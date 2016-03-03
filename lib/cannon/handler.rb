module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    attr_accessor :app

    def process_http_request
      response = Response.new(self, app)
      request = Request.new(self, app, response: response)

      app.reload_environment unless app.runtime.config.cache_app

      app.handle(request, response)

      unless request.handled?
        request.not_found
        request.finish
      end
    end
  end
end
