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

    ATTRIBUTES = %w(http_protocol http_request_method http_cookie http_content_type http_request_uri http_query_string
                    http_post_content http_headers http_path_info)
    def to_h
      hash = {}
      ATTRIBUTES.each { |attr| hash[attr] = instance_variable_get("@#{attr}") || '' }
      hash
    end

    private

    def request
      @request ||= Request.new(self.to_h, app)
    end

    def response
      @response ||= Response.new(RecordedDelegatedResponse.new(self), app)
    end

    def handle_request
      request.start_benchmarking if app.runtime.config[:benchmark_requests]
      app.handle(request, response)
      response.not_found unless request.handled?
      request.benchmark_request(logger: app.logger) if app.runtime.config[:benchmark_requests]
    end
  end
end
