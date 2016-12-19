require 'pry'
require 'lspace/eventmachine'

module Cannon
  class AlreadyListening < StandardError; end

  class App
    attr_reader :routes, :app_binding

    def initialize(app_binding, port: nil, ip_address: nil)
      @app_binding = app_binding
      @subapps = {}

      opts = @app_binding.eval('ARGV')
      if index = opts.index('-p')
        port ||= opts[index + 1]
      end

      runtime.config.port = port unless port.nil?
      runtime.config.ip_address = ip_address unless ip_address.nil?
    end

    def mount(app, at:)
      @subapps[at] = app
      app.mount_on(self)
    end

    def console
      command_set = Pry::CommandSet.new {}
      Pry.start binding, commands: command_set
    end

    def listen(port: runtime.config.port, ip_address: runtime.config.ip_address, async: false)
      raise AlreadyListening, 'App is currently listening' unless @server_thread.nil?

      $LOAD_PATH << runtime.root

      server_block = ->(notifier) do
        EventMachine::run {
          server = EventMachine::start_server(ip_address, port, Cannon::Handler) do |handler|
            handler.app = self
          end
          notifier << server unless notifier.nil? # notify the calling thread that the server started if async
          logger.info "Cannon listening on port #{port}..."

          LSpace.rescue StandardError do |error|
            if LSpace[:request] && LSpace[:app]
              LSpace[:app].handle_error(error, request: LSpace[:request])
            else
              raise error
            end
          end
        }
      end

      trap_signals

      if async
        notification = Queue.new
        Thread.abort_on_exception = true
        @server_thread = Thread.new { server_block.call(notification) }
        notification.pop
      else
        server_block.call(nil)
      end
    end

    def handle_error(error, request:)
      logger.error error.message
      logger.error error.backtrace.join("\n")
      request.internal_server_error(title: error.message, content: error.backtrace.join('<br/>'))
      request.finish
    end

    def stop
      return if @server_thread.nil?
      EventMachine::stop_event_loop
      @server_thread.join(10)
      @server_thread.kill unless @server_thread.stop?
      Thread.abort_on_exception = false
      @server_thread = nil
      logger.info "Cannon no longer listening"
    end

    def config
      @config ||= Config.new
    end

    def mount_on(app)
      @mounted_on = app
    end

    def runtime
      @mounted_on&.runtime || (@runtime ||= Runtime.new(@app_binding))
    end

    def cache
      runtime.cache
    end

    def logger
      runtime.logger
    end

    def handle(request, response)
      @subapps.each do |mounted_at, subapp|
        mount_matcher = /^#{mounted_at}/

        if request.path =~ mount_matcher
          original_path = request.path.dup
          request.path.gsub!(mount_matcher, '')
          subapp.handle(request, response)
          request.path = original_path
        end
      end
    end

  private

    def trap_signals
      trap('INT') do
        puts 'Caught interrupt; shutting down...'
        stop
        exit
      end

      trap('TERM') do
        puts 'Caught term signal; shutting down...'
        stop
        exit
      end
    end
  end
end
