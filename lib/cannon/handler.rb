module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    def app
      # magically defined by Cannon::App
      self.class.app
    end

    def process_http_request
      request = HttpRequest.new(self)
      response = HttpResponse.new(self)

      matched_route = app.routes.find { |route| route.matches? request.path }

      if matched_route.nil?
        response.not_found
      else
        puts "GET #{matched_route.path}"
        EM.defer(matched_route.function_block(app, request, response), ->(result) { response.send })
      end
    end
  end
end
