module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    attr_accessor :app

    def process_http_request
      response = Response.new(self, app)
      request = Request.new(self, app, response: response)

      app.ensure_latest_app_loaded unless app.runtime.config.cache_app

      LSpace.with(request: request, response: response, app: app) do
        begin
          app.handle(request, response)
        rescue => error
          app.handle_error(error, request: request)
        ensure
          unless request.handled?
            request.not_found
            request.finish
          end
        end
      end
    end
  end
end
