module Cannon
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        return next_proc.call if request.handled?

        matched_route = @app.routes.find { |route| route.matches? request }
        matched_route&.handle(request, response, next_proc)
      end
    end
  end
end
