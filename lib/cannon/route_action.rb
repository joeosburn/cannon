module Cannon
  class RouteAction
    include EventMachine::Deferrable

    class << self
      def controller(name, app)
        controllers[name] ||= Object.const_get(name).new(app)
      end

      def controllers
        @controllers ||= {}
      end

      def build(app, actions, callback: nil)
        return callback if actions.size < 1

        route_action = new(app, actions.pop, callback: callback)
        build(app, actions, callback: route_action)
      end
    end

    attr_reader :action, :app

    def initialize(app, action, callback:)
      @app = app
      @action = action
      @callback = callback
    end

    def last_action
      @callback.nil? ? self : @callback.last_action
    end

    def handle(request, response, finish_proc)
      request.handle!
      run_action(request, response, next_proc(request, response, finish_proc))
    end

    def run_action(request, response, next_proc)
      if action.is_a? Proc
        run_inline_action(request, response, next_proc)
      elsif action.include? '#'
        run_controller_action(request, response, next_proc)
      else
        run_bound_action(request, response, next_proc)
      end
    end

  private

    def next_proc(request, response, finish_proc)
      next_proc = -> do
        if response.flushed?
          fail
          finish_proc.call
        else
          setup_callback
          succeed(request, response, finish_proc)
        end
      end
    end

    def run_inline_action(request, response, next_proc)
      app.logger.debug 'Action: Inline'

      if action.arity == 2
        action.call(request, response)
        next_proc.call
      else
        action.call(request, response, next_proc)
      end
    end

    def run_controller_action(request, response, next_proc)
      controller, action_name = action.split('#')

      app.logger.debug "Controller: #{controller}, Action: #{action_name}"

      controller_instance = RouteAction.controller(controller, app)
      if controller_instance.method(action_name).arity == 2
        controller_instance.send(action_name, request, response)
        next_proc.call
      else
        controller_instance.send(action_name, request, response, next_proc)
      end
    end

    def run_bound_action(request, response, next_proc)
      app.logger.debug "Action: #{action}"

      if app.app_binding.method(action).arity == 2
        app.app_binding.send(action, request, response)
        next_proc.call
      else
        app.app_binding.send(action, request, response, next_proc)
      end
    end

    def setup_callback
      set_deferred_status nil
      callback do |request, response, finish_proc|
        if @callback.nil?
          finish_proc.call
        else
          @callback.handle(request, response, finish_proc)
        end
      end
    end
  end

  class CachingRouteAction < RouteAction
    def action_cache
      return @action_cache if defined? @action_cache
      @action_cache = begin
        if app.runtime.config.cache_app && !action.is_a?(Proc)
          ActionCache.new(self, cache: app.runtime.cache)
        end
      end
    end

    def handle(request, response, finish_proc)
      request.handle!

      if request.method == 'GET' && action_cache
        action_cache.run_action(request, response, next_proc(request, response, finish_proc))
      else
        run_action(request, response, next_proc(request, response, finish_proc))
      end
    end
  end

  class RedirectRouteAction
    def initialize(location)
      @location = location
    end

    def handle(request, response, next_proc)
      request.handle!
      response.permanent_redirect(redirect)
    end
  end
end
