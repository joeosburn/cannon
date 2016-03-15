require 'pry'
require 'lspace/eventmachine'

module Cannon
  class AlreadyListening < StandardError; end

  class App
    attr_reader :routes, :app_binding

    def initialize(app_binding, port: nil, ip_address: nil)
      @app_binding = app_binding
      @subapps = {}
      @routes = []

      opts = @app_binding.eval('ARGV')
      if index = opts.index('-p')
        port ||= opts[index + 1]
      end

      runtime.config.port = port unless port.nil?
      runtime.config.ip_address = ip_address unless ip_address.nil?
    end

    %w{get post put patch delete head all}.each do |http_method|
      define_method(http_method) do |path, action: nil, actions: nil, redirect: nil, cache: true, &block|
        add_route(path,
          method: http_method.to_sym,
          actions: [block, action, actions].flatten.compact,
          redirect: redirect,
          cache: cache
        )
      end
    end

    def mount(app, at:)
      @subapps[at] = app
      app.mount_on(self)
    end

    def listen(port: runtime.config.port, ip_address: runtime.config.ip_address, async: false)
      if ENV['CONSOLE']
        command_set = Pry::CommandSet.new {}
        Pry.start binding, commands: command_set
        exit
      end

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

    def ensure_latest_app_loaded
      $LOADED_FEATURES.each { |feature| load_file_if_changed_for_app(feature) }
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

        return if request.handled?
      end

      middleware_runner.run(request, response) unless config.middleware.size == 0
    end

  private

    def load_file_if_changed_for_app(file)
      return unless file =~ /^#{runtime.root}/
      mtime = File.mtime(file)
      load_file(file, mtime: mtime) if file_mtimes[file] != mtime
    end

    def load_file(file, mtime:)
      load file
      file_mtimes[file] = mtime
    end

    def file_mtimes
      @file_mtimes ||= {}
    end

    def middleware_runner
      @middleware_runner ||= build_middleware_runner(prepared_middleware_stack)
    end

    def prepared_middleware_stack
      config.middleware.dup
    end

    def build_middleware_runner(middleware, callback: nil)
      return callback if middleware.size < 1

      middleware_runner = MiddlewareRunner.new(middleware.pop, callback: callback, app: self)
      build_middleware_runner(middleware, callback: middleware_runner)
    end

    def add_route(path, method:, actions:, redirect:, cache:, &block)
      route = Route.new(path, app: self, method: method, actions: actions, redirect: redirect, cache: cache)
      routes << route
      extra_router(route)
    end

    def extra_router(route)
      ExtraRouter.new(self, route)
    end

    class ExtraRouter
      def initialize(app, route)
        @app = app
        @route = route
      end

      def handle(&block)
        @route.add_route_action(block)
        self
      end
    end
  end
end
