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

  def initialize(app, action:, callback:)
    @app, @action, @callback = app, action, callback
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

    if @action.is_a? Proc
      run_inline_action(request, response, next_proc)
    elsif @action.include? '#'
      run_controller_action(request, response, next_proc)
    else
      run_bound_action(request, response, next_proc)
    end
  end

private

  def run_inline_action(request, response, next_proc)
    Cannon.logger.debug 'Action: Inline'

    if @action.arity == 2
      @action.call(request, response)
      next_proc.call
    else
      @action.call(request, response, next_proc)
    end
  end

  def run_controller_action(request, response, next_proc)
    controller, action = @action.split('#')

    Cannon.logger.debug "Controller: #{controller}, Action: #{action}"

    controller_instance = RouteAction.controller(controller, @app)
    if controller_instance.method(action).arity == 2
      controller_instance.send(action, request, response)
      next_proc.call
    else
      controller_instance.send(action, request, response, next_proc)
    end
  end

  def run_bound_action(request, response, next_proc)
    Cannon.logger.debug "Action: #{@action}"

    if @app.app_binding.method(@action).arity == 2
      @app.app_binding.send(@action, request, response)
      next_proc.call
    else
      @app.app_binding.send(@action, request, response, next_proc)
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
