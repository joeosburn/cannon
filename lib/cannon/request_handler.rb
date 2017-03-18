module Cannon
  # The main handler class for incoming requests
  class RequestHandler < EventMachine::Connection
    include Chase::Server

    attr_reader :app

    def handle
      LSpace.with(request: request, response: cannon_response, app: app) do
        begin
          app.handle(request, cannon_response)
        rescue StandardError => error
          app.handle_error(error, request, cannon_response)
        end
      end
    end

    def start(app)
      @app = app
    end

    private

    def cannon_response
      @cannon_response ||= Response.new(RecordableResponse.new(response))
    end
  end
end
