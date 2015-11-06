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

      puts "GET #{request.path}"

      matched_route = app.routes.find { |route| route.matches? request.path }

      if matched_route.nil?
        response.not_found
      else
        matched_route.handle(request, response)
      end
    end
  end
end
