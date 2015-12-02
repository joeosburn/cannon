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

  def run(request, response)
    next_proc = -> do
      if response.flushed?
        fail
      else
        setup_callback
        succeed(request, response)
      end
    end

    if @action.is_a? Proc
      Cannon.logger.debug 'Action: Inline'
      @action.call(request, response, next_proc)
    elsif @action.include? '#'
      controller, action = @action.split('#')
      Cannon.logger.debug "Controller: #{controller}, Action: #{action}"
      RouteAction.controller(controller, @app).send(action, request, response, next_proc)
    else
      Cannon.logger.debug "Action: #{@action}"
      @app.app_binding.send(@action, request, response, next_proc)
    end
  end

private

  def setup_callback
    set_deferred_status nil
    callback do |request, response|
      @callback.run(request, response) unless @callback.nil?
    end
  end
end
