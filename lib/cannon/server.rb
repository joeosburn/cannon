module Cannon
  # Cannon server thread
  class Server < Thread
    extend Forwardable

    class << self
      def start(app)
        trap_signals(start_server(app)).pop
      end

      def start_async(app)
        start_server(app).tap { |server| trap_signals(server) }
      end

      def stop(server, notifier = nil)
        Thread.new do
          server.stop(notifier)
          server.kill unless server.stop?
        end
      end

      private

      def start_server(app)
        new(app).tap { |server| server.notifier.pop }
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

    attr_reader :app

    delegate logger: :app, ip_address: :app, port: :app

    def initialize(*args)
      self.class.abort_on_exception = true
      @app = args[0]
      super(args) { server_proc.call(app, notifier) }
      logger.info "Cannon listening on port #{port}..."
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

    def server_proc
      proc do |app, notifier|
        EventMachine.run do
          EventMachine.start_server(app.ip_address, app.port, Cannon::RequestHandler, &new_handler_proc(app))
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
  end
end
