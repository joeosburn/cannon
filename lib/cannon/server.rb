module Cannon
  # Cannon server thread
  class Server < Thread
    extend Forwardable

    class << self
      def start(app, options = {})
        trap_signals(start_server(app, OptionsBuilder.new(options).merge.options)).pop
      end

      def start_async(app, options = {})
        start_server(app, OptionsBuilder.new(options).merge.options).tap { |server| trap_signals(server) }
      end

      def stop(server, notifier = nil)
        Thread.new do
          server.stop(notifier)
          server.kill unless server.stop?
        end
      end

      private

      def start_server(app, options)
        new(app, options[:ip_address], options[:port]).tap { |server| server.notifier.pop }
      end

      def trap_signals(server)
        Queue.new.tap do |notifier|
          trap_signal('INT', server, notifier)
          trap_signal('TERM', server, notifier)
        end
      end

      def trap_signal(signal, server, notifier)
        trap(signal) do
          puts "Caught #{signal} signal; shutting down..."
          stop(server, notifier)
        end
      end
    end

    attr_reader :app, :port, :ip_address

    delegate logger: :app

    def initialize(*args)
      self.class.abort_on_exception = true
      assign_args(*args)
      super(args) { server_proc.call(app, notifier) }
      logger.info "Cannon listening on #{ip_address}, port #{port}..."
    end

    def stop(notifier = nil)
      EventMachine.stop_event_loop
      logger.info 'Cannon shutting down...'
      join(10)
      notifier << self if notifier
    end

    def notifier
      @notifier ||= Queue.new
    end

    private

    def assign_args(*args)
      @app = args[0]
      @ip_address = args[1] || '127.0.0.1'
      @port = args[2] || 5030
    end

    def server_proc
      proc do |app, notifier|
        EventMachine.run do
          EventMachine.start_server(ip_address, port, Cannon::RequestHandler, &new_handler_proc(app))
          LSpace.rescue(StandardError, &lspace_rescue_proc)
          notifier << self
        end
      end
    end

    def lspace_rescue_proc
      proc do |error|
        LSpace[:app].tap do |app|
          raise error unless app
          app.handle_error(error, LSpace[:request], LSpace[:response])
        end
      end
    end

    def new_handler_proc(app)
      proc { |handler| handler.start(app) }
    end

    # Builds options for server
    class OptionsBuilder
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def merge(args = ARGV)
        options_parser.parse!(args)
        self
      end

      private

      def options_parser
        @options_parser ||= OptionParser.new do |opts|
          opts.banner = "#{Pathname.new($PROGRAM_NAME).basename} #{ARGV[0]} [options]"

          opts.on('-pPORT', '--port=PORT', 'Port to run on') do |port|
            options[:port] ||= port
          end

          opts.on('-bBINDING', '--binding=IP', 'IP Address to run on') do |ip_address|
            options[:ip_address] ||= ip_address
          end

          opts.on('-h', '--help', 'Prints this help') do
            puts opts
            exit
          end
        end
      end
    end
  end
end
