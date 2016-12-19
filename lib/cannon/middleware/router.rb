module Cannon
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        return next_proc.call if request.handled?

        if route = routes.route_for_request(request)
          route_action = routes[route]
          request.handle!
          inject_route_params_into_request!(route, request) if route_action.needs_params?
          route_action.handle(request, response, next_proc)
        end
      end

      def route(route, actions)
        routes[route] = RouteAction.build(@app, actions)
      end

      def cached_route(route, actions)
        routes[route] = CachingRouteAction.build(@app, actions)
      end

      def redirect(route, location)
        routes[route] = RedirectRouteAction.new(location)
      end

    private

      def routes
        @routes ||= Routes.new
      end

      def inject_route_params_into_request!(route, request)
        matches = route.path_matches(request.path)

        for index in 0...route.params.size
          request.params[route.params[index].to_sym] = matches.captures[index]
        end
      end
    end

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
        @routes.find(-> { [] }) { |route, route_action| route.matches? request }[0]
      end
    end
  end

  module AppRouting
    %w{get post put patch delete head all}.each do |http_method|
      define_method(http_method) do |path, action: nil, actions: nil, redirect: nil, cache: true, &block|
        route = Route.new(path, http_method)
        actions = [block, action, actions].flatten.compact

        if redirect
          router.redirect(route, redirect)
        elsif cache
          router.cached_route(route, actions)
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
