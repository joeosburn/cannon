module Cannon
  class Route
    attr_reader :path, :actions, :redirect

    def initialize(app, path:, actions: nil, redirect: nil)
      path = '/' + path unless path =~ /^\// # ensure path begins with '/'

      @app, @path, @redirect = app, path, redirect
      @actions = actions || []
      @route_action = build_route_action(@actions.dup)
    end

    def matches?(path)
      self.path == path
    end

    def handle(request, response)
      if redirect
        response.permanent_redirect(redirect)
      elsif @route_action
        EM.defer(
          -> { @route_action.run(request, response) },
          ->(result) { response.send }
        )
      end
    end

    def to_s
      "Route: '#{path}'"
    end

  private

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

      callback do
        @callback.run(@request, @response) unless @callback.nil?
      end
    end

    def run(request, response)
      @request, @response = request, response
      puts "Running action #{@action}"
      @app.actions_binding.send(@action, request, response)
      @response.sent? ? self.fail : self.succeed
    end
  end
end
