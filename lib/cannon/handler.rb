module Cannon
  # The main handler class for incoming requests
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    attr_accessor :app

    def process_http_request
      response = Response.new(RecordedDelegatedResponse.new(self), app: app)
      request = Request.new(self, app)

      lspace_process(request, response)
    end

  private

    def lspace_process(request, response)
      LSpace.with(request: request, response: response, app: app) do
        begin
          app.handle(request, response)
        rescue StandardError => error
          app.handle_error(error, request, response)
        ensure
          unless request.handled?
            response.not_found
            response.flush
            request.finish
          end
        end
      end
    end
  end
end
