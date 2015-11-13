require 'mime/types'

module Cannon
  class App
    attr_reader :routes, :app_binding

    DEFAULT_MIDDLEWARE = %w{RequestLogger Files Router ContentType}

    def initialize(app_binding, &block)
      @app_binding = app_binding
      @routes = []
      @load_environment = block

      config.middleware = DEFAULT_MIDDLEWARE
      config.public_path = 'public'
      config.view_path = 'views'

      define_cannon_environment
      define_cannon_root
      define_cannon_mime_type
      define_cannon_config
    end

    def get(path, action: nil, actions: nil, redirect: nil, &block)
      routes << Route.new(self, path: path, actions: [block, action, actions].flatten.compact, redirect: redirect)
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

    def config
      @config ||= create_config
    end

  private

    def create_config
      Struct.new(:middleware, :public_path, :view_path).new
    end

    def define_cannon_environment
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

    def define_cannon_config
      cannon_method(:config, self.config)
    end

    def define_cannon_root
      cannon_method(:root, @app_binding.eval('File.expand_path(File.dirname(__FILE__))'))
    end

    def define_cannon_mime_type
      Cannon.send(:define_method, :mime_type, ->(filepath) { MIME::Types.type_for(filepath.split('/').last).first })
      Cannon.send(:module_function, :mime_type)
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
