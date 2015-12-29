module Cannon
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        matched_route = @app.routes.find { |route| route.matches? request }
        if matched_route.nil?
          response.not_found
          next_proc.call
        else
          matched_route.handle(request, response, next_proc)
        end
      end
    end
  end
end
