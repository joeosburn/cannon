module Cannon
  class App
    attr_reader :routes, :actions_binding

    def initialize(actions_binding)
      @routes = []
      @actions_binding = actions_binding
    end

    def get(path, action: nil, actions: nil, redirect: nil)
      routes << Route.new(path, actions: [action, actions].flatten.compact, redirect: redirect)
    end

    def listen(port = 8080)
      cannon_app = self
      Cannon::Handler.define_singleton_method(:app) { cannon_app }

      EventMachine::run {
        EventMachine::start_server('127.0.0.1', port, Cannon::Handler)
        puts "Listening on port #{port}..."
      }
    end
  end

  class Route
    attr_reader :path, :actions, :redirect

    def initialize(path, actions: nil, redirect: nil)
      path = '/' + path unless path =~ /^\// # ensure path begins with '/'
      @path = path
      @actions = actions
      @redirect = redirect
    end

    def matches?(path)
      self.path == path
    end

    def handle(app, request, response)
      if redirect
        response.permanent_redirect(redirect)
      elsif actions and actions.size > 0
        EM.defer(action_block(app, request, response), ->(result) { response.send })
      end
    end

    def to_s
      "Route: '#{path}'"
    end

  private

    def action_block(app, request, response)
      remaining_actions = actions.dup
      -> { RouteAction.new(app, remaining_actions.shift, request, response, remaining_actions).run }
    end
  end

  class RouteAction
    include EventMachine::Deferrable

    def initialize(app, function, request, response, remaining_actions)
      @app, @function, @request, @response, @remaining_actions = app, function, request, response, remaining_actions

      callback do
        if @remaining_actions.size > 0
          function = RouteAction.new(@app, @remaining_actions.shift, @request, @response, @remaining_actions)
          function.run
        end
      end
    end

    def run
      puts "Running action #{@function}"
      @app.actions_binding.send(@function, @request, @response)
      @response.sent? ? self.fail : self.succeed
    end
  end
end
