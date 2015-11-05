module Cannon
  class App
    attr_reader :routes, :handlers_binding

    def initialize(handlers_binding)
      @routes = []
      @handlers_binding = handlers_binding
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

    def to_s
      path
    end
  end
end
