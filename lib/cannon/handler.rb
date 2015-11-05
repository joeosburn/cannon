module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    def app
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
        functions = matched_route.functions.dup
        run_handlers = -> { HandlerFunction.new(self, functions.shift, request, response, functions).run }

        EM.defer(run_handlers, ->(result) { response.send })
      end

      # Let the thread pool (20 Ruby threads) handle request
      # EM.defer(operation, callback)
    end
  end

  class HandlerFunction
    include EventMachine::Deferrable

    def initialize(handler, function, request, response, remaining_handlers)
      @handler, @function, @request, @response, @remaining_handlers = handler, function, request, response, remaining_handlers

      callback do
        if @remaining_handlers.size > 0
          function = HandlerFunction.new(handler, @remaining_handlers.shift, @request, @response, @remaining_handlers)
          function.run
        end
      end
    end

    def run
      @handler.app.handlers_binding.send(@function, @request, @response)
      @response.sent? ? self.fail : self.succeed
    end
  end
end
