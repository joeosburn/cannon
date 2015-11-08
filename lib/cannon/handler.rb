module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    def app
      # magically defined by Cannon::App
      self.class.app
    end

    def process_http_request
      request = Request.new(self, app)
      response = Response.new(self, app)

      app.reload_environment if Cannon.env.development?

      EM.defer(
        -> { middleware_runner.run(request, response) if middleware? },
        ->(result) do
          response.flush unless response.flushed?
          puts "Response took #{time_ago_in_ms(request.start_time)} milliseconds" if Cannon.env.development?
        end
      )
    end

  private

    def time_ago_in_ms(time_ago)
      Time.at((Time.now - time_ago)).strftime('%6N').to_i/1000.0
    end

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
