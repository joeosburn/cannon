module Cannon
  class App
    attr_reader :routes, :actions_binding
    attr_accessor :middleware

    def initialize(actions_binding, middleware: [])
      @routes = []
      @actions_binding = actions_binding

      self.middleware = [middleware].flatten
    end

    def get(path, action: nil, actions: nil, redirect: nil)
      routes << Route.new(self, path: path, actions: [action, actions].flatten.compact, redirect: redirect)
    end

    def listen(port: 8080)
      cannon_app = self
      Cannon::Handler.define_singleton_method(:app) { cannon_app }

      EventMachine::run {
        EventMachine::start_server('127.0.0.1', port, Cannon::Handler)
        puts "Cannon listening on port #{port}..."
      }
    end
  end
end
