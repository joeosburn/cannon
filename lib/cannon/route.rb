module Cannon
  class Route
    attr_reader :path, :actions, :redirect

    def initialize(app, path:, actions: nil, redirect: nil)
      @path = build_path(path)
      @app, @redirect = app, redirect
      @actions = actions || []
      @route_action = build_route_action(@actions.dup)
    end

    def matches?(request)
      matches = self.path.match(request.path)
      if matches.nil?
        false
      else
        @params.each_with_index { |key, index| request.params[key.to_sym] = matches.captures[index] }
        true
      end
    end

    def handle(request, response)
      if redirect
        response.permanent_redirect(redirect)
      elsif @route_action
        begin
          @route_action.run(request, response)
        rescue => error
          Cannon.logger.error error.message
          Cannon.logger.error error.backtrace.join("\n")
          response.internal_server_error(title: error.message, content: error.backtrace.join('<br/>'))
        end
      end
    end

    def to_s
      "Route: #{path}"
    end

  private

    def build_path(path)
      path = '/' + path unless path =~ /^\// # ensure path begins with '/'
      @params = []

      if path.include? ':'
        param_path_to_regexp(path)
      else
        /^#{path.gsub('/', '\/')}$/
      end
    end

    def param_path_to_regexp(path)
      /^#{path.split('/').map { |part| normalize_path_part(part) }.join('\/')}$/
    end

    def normalize_path_part(part)
      if part =~ /^:(.+)/
        @params << $1
        '([^\/]+)'
      else
        part
      end
    end

    def build_route_action(actions, callback: nil)
      return callback if actions.size < 1

      route_action = RouteAction.new(@app, action: actions.pop, callback: callback)
      build_route_action(actions, callback: route_action)
    end
  end

  class RouteAction
    include EventMachine::Deferrable

    def initialize(app, action:, callback:)
      @app, @action, @callback = app, action, callback
    end

    def run(request, response)
      if @action.is_a? Proc
        Cannon.logger.debug 'Action: Inline'
        @action.call(request, response)
      elsif @action.include? '#'
        controller, action = @action.split('#')
        Object.const_get(controller).new(@app).send(action, request, response)
      else
        Cannon.logger.debug "Action: #{@action}"
        @app.app_binding.send(@action, request, response)
      end

      if response.flushed?
        fail
      else
        setup_callback
        succeed(request, response)
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
end
