module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    attr_accessor :app

    def process_http_request
      request = Request.new(self, app)
      response = Response.new(self, app, request: request)

      app.reload_environment if app.runtime.config.reload_on_request

      app.handle(request, response)

      unless request.handled?
        response.not_found
        response.finish
      end
    end
  end
end
