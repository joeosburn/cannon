module Cannon
  class App
    attr_reader :routes, :functions_binding

    def initialize(functions_binding)
      @routes = []
      @functions_binding = functions_binding
    end

    def get(path, *functions)
      routes << Route.new(path, functions: functions)
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
    attr_reader :path, :functions

    def initialize(path, functions:)
      path = '/' + path unless path =~ /^\// # ensure path begins with '/'
      @path = path
      @functions = functions
    end

    def matches?(path)
      self.path == path
    end

    def function_block(app, request, response)
      remaining_functions = functions.dup
      -> { RouteFunction.new(app, remaining_functions.shift, request, response, remaining_functions).run }
    end

    def to_s
      "Route: '#{path}'"
    end
  end

  class RouteFunction
    include EventMachine::Deferrable

    def initialize(app, function, request, response, remaining_functions)
      @app, @function, @request, @response, @remaining_functions = app, function, request, response, remaining_functions

      callback do
        if @remaining_functions.size > 0
          function = RouteFunction.new(@app, @remaining_functions.shift, @request, @response, @remaining_functions)
          function.run
        end
      end
    end

    def run
      @app.functions_binding.send(@function, @request, @response)
      @response.sent? ? self.fail : self.succeed
    end
  end
end
