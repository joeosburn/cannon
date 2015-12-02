module Cannon
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        matched_route = @app.routes.find { |route| route.matches? request }
        matched_route.nil? ? response.not_found : matched_route.handle(request, response)
        next_proc.call
      end
    end
  end
end
