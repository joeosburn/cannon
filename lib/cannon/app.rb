module Cannon
  class App
    attr_reader :routes, :app_binding
    attr_accessor :middleware, :public_path

    def initialize(app_binding, middleware: [], public_path: 'public', &block)
      @app_binding = app_binding
      @routes = []
      @load_environment = block

      self.middleware = [middleware].flatten
      self.public_path = public_path

      define_environment
      define_root
    end

    def get(path, action: nil, actions: nil, redirect: nil)
      routes << Route.new(self, path: path, actions: [action, actions].flatten.compact, redirect: redirect)
    end

    def listen(port: 8080)
      cannon_app = self
      Cannon::Handler.define_singleton_method(:app) { cannon_app }

      $LOAD_PATH << Cannon.root
      reload_environment if Cannon.env.production?

      EventMachine::run {
        EventMachine::start_server('127.0.0.1', port, Cannon::Handler)
        puts "Cannon listening on port #{port}..."
      }
    end

    def reload_environment
      @load_environment.call unless @load_environment.nil?
    end

  private

    def define_environment
      cannon_method(:env, ENV['CANNON_ENV'] ? ENV['CANNON_ENV'].dup : 'development')
      class << Cannon.env
        def production?
          self == 'production'
        end

        def development?
          self == 'development'
        end
      end
    end

    def define_root
      cannon_method(:root, @app_binding.eval('File.expand_path(File.dirname(__FILE__))'))
    end

    def cannon_method(name, value)
      Cannon.send(:define_method, name.to_sym, -> { value })
      Cannon.send(:module_function, name.to_sym)
    end
  end
end

module Kernel
  def reload(lib)
    if old = $LOADED_FEATURES.find{ |path| path=~/#{Regexp.escape lib}(\.rb)?\z/ }
      load old
    else
      require lib
    end
  end
end
