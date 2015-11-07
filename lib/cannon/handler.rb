module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    def app
      # magically defined by Cannon::App
      self.class.app
    end

    def process_http_request
      app.reload_environment if Cannon.env == 'development'

      request = Request.new(self)
      response = Response.new(self)

      EM.defer(
        -> { middleware_runner.run(request, response) if middleware? },
        ->(result) { response.send unless response.sent? }
      )
    end

  private

    def middleware?
      app.middleware.size > 0
    end

    def middleware_runner
      @middleware_runner ||= build_middleware_runner(app.middleware.dup)
    end

    def build_middleware_runner(middleware, callback: nil)
      return callback if middleware.size < 1

      middleware_runner = MiddlewareRunner.new(middleware.pop, callback: callback, app: app)
      build_middleware_runner(middleware, callback: middleware_runner)
    end
  end
end
