module Cannon
  class App
    attr_reader :routes, :app_binding
    attr_accessor :middleware, :public_path

    def initialize(app_binding, middleware: [], public_path: 'public')
      @routes = []
      @app_binding = app_binding

      self.middleware = [middleware].flatten
      self.public_path = public_path
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
