module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    class << self
      def middleware_runner
        @middleware_runner ||= build_middleware_runner(prepared_middleware_stack)
      end

    private

      def prepared_middleware_stack
        stack = app.config.middleware.dup
        stack << 'FlushAndBenchmark'
      end

      def build_middleware_runner(middleware, callback: nil)
        return callback if middleware.size < 1

        middleware_runner = MiddlewareRunner.new(middleware.pop, callback: callback, app: app)
        build_middleware_runner(middleware, callback: middleware_runner)
      end
    end

    def app
      # magically defined by Cannon::App
      self.class.app
    end

    def process_http_request
      request = Request.new(self, app)
      response = Response.new(self, app)

      app.reload_environment if app.config.reload_on_request

      self.class.middleware_runner.run(request, response) if middleware?
    end

  private

    def middleware?
      app.config.middleware.size > 0
    end
  end
end
