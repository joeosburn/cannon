module Cannon
  module Middleware
    # Middleware for handling routing logic
    class Router
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        route = @app.routes.route_for_request(request)
        return next_proc.call unless route

        request.params.merge!(route.path_params(request.path)) if route.needs_params?
        @app.routes[route].handle(request, response, next_proc)
      end
    end

    # Simple class for storing hash with the pattern of a key of a route and a value of a route action
    class Routes
      def initialize
        @routes = {}
      end

      def []=(route, actions)
        @routes[route] = actions
      end

      def [](route)
        @routes[route]
      end

      def route_for_request(request)
        @routes.find(-> { [] }) { |route, _route_action| route.matches? request }[0]
      end
    end
  end

  # Additional functionality to be added App for routing support
  module AppRouting
    %w(get post put patch delete head all).each do |http_method|
      define_method(http_method) do |path, options = {}, &block|
        route = Route.new(path, http_method)
        actions = [block, options[:action], options[:actions]].flatten.compact

        if options[:redirect]
          routes[route] = RedirectRouteAction.new(location)
        elsif options.fetch(:cache, true)
          routes[route] = RouteAction.caching_route_actions(self, actions)
        else
          routes[route] = RouteAction.route_actions(self, actions)
        end
      end
    end

    def routes
      @routes ||= Cannon::Middleware::Routes.new
    end
  end
end

Cannon::App.include Cannon::AppRouting
