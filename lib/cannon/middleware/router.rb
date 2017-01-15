module Cannon
  module Middleware
    # Middleware for handling routing logic
    class Router
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        return next_proc.call if request.handled?

        handle(request, response, next_proc)
      end

      def route(route, actions)
        routes[route] = RouteAction.route_actions(@app, actions)
      end

      def caching_route(route, actions)
        routes[route] = RouteAction.caching_route_actions(@app, actions)
      end

      def redirect(route, location)
        routes[route] = RedirectRouteAction.new(location)
      end

      private

      def routes
        @routes ||= Routes.new
      end

      def handle(request, response, next_proc)
        route = routes.route_for_request(request)
        return unless route

        request.params.merge!(route.path_params(request.path)) if route.needs_params?
        routes[route].handle(request, response, next_proc)
      end
    end

    # Simple class for storing hash with the pattern of a key of a route and a value of a route action
    class Routes
      def initialize
        @routes = {}
      end

      def []=(route, route_action)
        @routes[route] = route_action
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
          router.redirect(route, options[:redirect])
        elsif options.fetch(:cache, true)
          router.caching_route(route, actions)
        else
          router.route(route, actions)
        end
      end
    end

    def router
      middleware['Router']
    end
  end
end

Cannon::App.include Cannon::AppRouting
