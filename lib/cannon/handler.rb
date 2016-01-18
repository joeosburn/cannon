module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    def app
      # magically defined by Cannon::App
      self.class.app
    end

    def process_http_request
      request = Request.new(self, app)
      response = Response.new(self, app, request: request)

      app.reload_environment if Cannon.config.reload_on_request

      app.middleware_runner.run(request, response) if middleware?
    end

  private

    def middleware?
      app.config.middleware.size > 0
    end
  end
end
