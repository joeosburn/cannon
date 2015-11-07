module Cannon
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def run(request, response)
        matched_route = @app.routes.find { |route| route.matches? request.path }
        matched_route.nil? ? response.not_found : matched_route.handle(request, response)
      end
    end
  end
end
