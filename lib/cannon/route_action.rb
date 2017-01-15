module Cannon
  # A RouteAction is an object which runs an action in response to a route being matched.
  # Typically, there will be one or more route actions associated with a single route,
  # which are created via the ::route_actions or ::caching_route_actions methods.
  class RouteAction
    include EventMachine::Deferrable

    class << self
      def route_actions(app, actions, callback = nil)
        return callback if actions.empty?

        route_action = route_action(app, actions.pop, callback)
        yield route_action if block_given?
        route_actions(app, actions, route_action)
      end

      def caching_route_actions(app, actions)
        route_actions(app, actions) { |route_action| route_action.with_cache if app.runtime.config[:cache_app] }
      end

      def route_action(app, action, callback)
        if action.is_a? Proc
          InlineRouteAction.new(app, action, callback)
        elsif action.include? '#'
          ControllerRouteAction.new(app, action, callback)
        else
          BoundRouteAction.new(app, action, callback)
        end
      end
    end

    attr_reader :action, :app, :action_cache

    def initialize(app, action, callback)
      @app = app
      @action = action
      @callback = callback
    end

    def handle(request, response, finish_proc)
      request.handle

      next_proc = generate_next_proc(request, response, finish_proc)

      if request.method == 'GET' && action_cache
        action_cache.run_action(request, response, next_proc)
      else
        run_action(request, response, next_proc)
      end
    end

    def with_cache
      @action_cache = begin
        ActionCache.new(self, cache: app.runtime.cache) unless action.is_a?(Proc)
      end
      self
    end

    private

    def generate_next_proc(request, response, finish_proc)
      lambda do
        if response.flushed?
          fail
          finish_proc.call
        else
          setup_callback
          succeed(request, response, finish_proc)
        end
      end
    end

    def setup_callback
      set_deferred_status nil
      callback do |request, response, finish_proc|
        if @callback
          @callback.handle(request, response, finish_proc)
        else
          finish_proc.call
        end
      end
    end
  end

  # RouteAction which calls an inline proc
  class InlineRouteAction < RouteAction
    def run_action(request, response, next_proc)
      app.logger.debug 'Action: Inline'

      if action.arity == 2
        action.call(request, response)
        next_proc.call
      else
        action.call(request, response, next_proc)
      end
    end
  end

  # RouteAction which calls a method from the binding of the app instantiation
  class BoundRouteAction < RouteAction
    def run_action(request, response, next_proc)
      app.logger.debug "Action: #{action}"

      if app_binding.method(action).arity == 2
        app_binding.send(action, request, response)
        next_proc.call
      else
        app_binding.send(action, request, response, next_proc)
      end
    end

    def app_binding
      @app_binding ||= app.app_binding
    end
  end

  # RouteAction which calls an action from persisting controller instance
  class ControllerRouteAction < RouteAction
    class << self
      def controller(name, app)
        controllers[name] ||= Object.const_get(name).new(app)
      end

      def controllers
        @controllers ||= {}
      end
    end

    def initialize(app, action, callback)
      super
      @controller, @action_name = action.split('#')
    end

    def run_action(request, response, next_proc)
      app.logger.debug "Controller: #{@controller}, Action: #{@action_name}"

      if controller_instance.method(@action_name).arity == 2
        controller_instance.send(@action_name, request, response)
        next_proc.call
      else
        controller_instance.send(@action_name, request, response, next_proc)
      end
    end

    private

    def controller_instance
      @controller_instance ||= self.class.controller(@controller, app)
    end
  end

  # RouteAction for Redirecting
  class RedirectRouteAction
    def initialize(location)
      @location = location
    end

    def handle(request, response, _next_proc)
      request.handle
      response.permanent_redirect(redirect)
    end
  end
end
