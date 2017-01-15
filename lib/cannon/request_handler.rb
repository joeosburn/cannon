module Cannon
  # The main handler class for incoming requests
  class RequestHandler < EventMachine::Connection
    include EventMachine::HttpServer

    attr_reader :app

    def process_http_request
      LSpace.with(request: request, response: response, app: app) do
        begin
          handle_request
        rescue StandardError => error
          app.handle_error(error, request, response)
        end
      end
    end

    def start(app)
      @app = app
    end

    private

    def request
      @request ||= Request.new(self, app)
    end

    def response
      @response ||= Response.new(RecordedDelegatedResponse.new(self), app)
    end

    def handle_request
      app.handle(request, response)
      response.not_found unless request.handled?
      request.finish
    end
  end
end
