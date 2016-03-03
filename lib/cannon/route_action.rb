class RouteAction
  include EventMachine::Deferrable

  class << self
    def controller(name, app)
      controllers[name] ||= Object.const_get(name).new(app)
    end

    def controllers
      @controllers ||= {}
    end
  end

  attr_writer :callback
  attr_reader :action, :app, :route

  def initialize(app, action:, route:, callback:)
    @app, @action, @callback, @route = app, action, callback, route
  end

  def last_action
    @callback.nil? ? self : @callback.last_action
  end

  def run(request, response, finish_proc)
    next_proc = -> do
      if response.flushed?
        fail
        finish_proc.call
      else
        setup_callback
        succeed(request, response, finish_proc)
      end
    end

    if route.cache? && app.runtime.config.cache_app
      app.runtime.action_cache.handle_route_action(self, request: request, response: response, next_proc: next_proc)
    else
      run_action(request, response, next_proc)
    end
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
        @callback.run(request, response, finish_proc)
      end
    end
  end
end
