require 'mime/types'

module Cannon
  class AlreadyListening < StandardError; end

  class App
    attr_reader :routes, :app_binding

    def initialize(app_binding, port: nil, ip_address: nil, &block)
      @app_binding = app_binding
      @routes = []
      @load_environment = block

      config.port = port unless port.nil?
      config.ip_address = ip_address unless ip_address.nil?

      define_cannon_environment
      define_cannon_root
      define_cannon_mime_type
      define_cannon_config
      define_cannon_configure_method
      define_cannon_logger
    end

    def get(path, action: nil, actions: nil, redirect: nil, &block)
      routes << Route.new(self, path: path, actions: [block, action, actions].flatten.compact, redirect: redirect)
    end

    def listen(port: config.port, ip_address: config.ip_address, async: false)
      raise AlreadyListening, 'App is currently listening' unless @running_app.nil?

      cannon_app = self
      Cannon::Handler.define_singleton_method(:app) { cannon_app }

      $LOAD_PATH << Cannon.root
      reload_environment unless config.reload_on_request

      server_block = -> do
        EventMachine::run {
          EventMachine::start_server(ip_address, port, Cannon::Handler)
          Cannon.logger.info "Cannon listening on port #{port}..."
        }
      end

      if async
        Thread.abort_on_exception = true
        @running_app = Thread.new { server_block.call }
      else
        server_block.call
      end
    end

    def stop
      return if @running_app.nil?
      EventMachine::stop_event_loop
      @running_app = nil
      Thread.abort_on_exception = false
    end

    def reload_environment
      @load_environment.call unless @load_environment.nil?
    end

    def configure(*environments, &block)
      environments.each do |environment|
        define_env_helper(environment)
        yield config if Cannon.env == environment.to_s
      end
    end

    def config
      @config ||= Config.new
    end

    def env
      @env ||= detect_env
    end

  private

    def detect_env
      ENV['CANNON_ENV'] ? ENV['CANNON_ENV'].dup : 'development'
    end

    def define_cannon_environment
      cannon_method(:env, self.env)
      define_env_helper(self.env)
    end

    def define_env_helper(env)
      helper_method = "#{env}?"
      return if Cannon.env.respond_to?(helper_method)
      Cannon.env.singleton_class.send(:define_method, helper_method) { Cannon.env == env }
    end

    def define_cannon_config
      cannon_method(:config, self.config)
    end

    def define_cannon_configure_method
      app = self
      Cannon.send(:define_method, :configure, ->(*environments, &block) { app.configure(*environments, &block) })
      Cannon.send(:module_function, :configure)
    end

    def define_cannon_root
      cannon_method(:root, @app_binding.eval('File.expand_path(File.dirname(__FILE__))'))
    end

    def define_cannon_logger
      app = self
      Cannon.send(:define_method, :logger, -> { app.config.logger })
      Cannon.send(:module_function, :logger)
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
