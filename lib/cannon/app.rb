require 'pry'

module Cannon
  class AlreadyListening < StandardError; end

  class App
    attr_reader :routes, :app_binding, :cache

    def initialize(app_binding, port: nil, ip_address: nil, &block)
      @app_binding = app_binding
      @routes = []
      @load_environment = block
      @cache = {}

      Cannon.config.port = port unless port.nil?
      Cannon.config.ip_address = ip_address unless ip_address.nil?

      define_cannon_root
      define_cannon_cache
    end

    %w{get post put patch delete head all}.each do |http_method|
      define_method(http_method) do |path, action: nil, actions: nil, redirect: nil, &block|
        add_route(path, method: http_method.to_sym, action: action, actions: actions, redirect: redirect, &block)
      end
    end

    def listen(port: Cannon.config.port, ip_address: Cannon.config.ip_address, async: false)
      cannon_app = self

      if ENV['CONSOLE']
        command_set = Pry::CommandSet.new {}
        Pry.start binding, commands: command_set
        exit
      end

      raise AlreadyListening, 'App is currently listening' unless @server_thread.nil?

      Cannon::Handler.define_singleton_method(:app) { cannon_app }

      $LOAD_PATH << Cannon.root
      reload_environment unless Cannon.config.reload_on_request

      server_block = ->(notifier) do
        EventMachine::run {
          server = EventMachine::start_server(ip_address, port, Cannon::Handler)
          notifier << server unless notifier.nil? # notify the calling thread that the server started if async
          Cannon.logger.info "Cannon listening on port #{port}..."
        }
      end

      if async
        notification = Queue.new
        Thread.abort_on_exception = true
        @server_thread = Thread.new { server_block.call(notification) }
        notification.pop
      else
        server_block.call(nil)
      end
    end

    def stop
      return if @server_thread.nil?
      EventMachine::stop_event_loop
      @server_thread.join(10)
      @server_thread.kill unless @server_thread.stop?
      Thread.abort_on_exception = false
      @server_thread = nil
      Cannon.logger.info "Cannon no longer listening"
    end

    def reload_environment
      @load_environment.call unless @load_environment.nil?
    end

    def config
      @config ||= AppConfig.new
    end

    def middleware_runner
      @middleware_runner ||= build_middleware_runner(prepared_middleware_stack)
    end

  private

    def prepared_middleware_stack
      stack = config.middleware.dup
      stack << 'FlushAndBenchmark'
    end

    def build_middleware_runner(middleware, callback: nil)
      return callback if middleware.size < 1

      middleware_runner = MiddlewareRunner.new(middleware.pop, callback: callback, app: self)
      build_middleware_runner(middleware, callback: middleware_runner)
    end

    def add_route(path, method:, action:, actions:, redirect:, &block)
      route = Route.new(self, method: method, path: path, actions: [block, action, actions].flatten.compact, redirect: redirect)
      routes << route
      extra_router(route)
    end

    def define_cannon_root
      cannon_method(:root, @app_binding.eval('File.expand_path(File.dirname(__FILE__))'))
    end

    def define_cannon_cache
      cannon_method(:cache, self.cache)
    end

    def define_cannon_logger
      app = self
      Cannon.send(:define_method, :logger, -> { app.config.logger })
      Cannon.send(:module_function, :logger)
    end

    def cannon_method(name, value)
      Cannon.send(:define_method, name.to_sym, -> { value })
      Cannon.send(:module_function, name.to_sym)
    end

    def extra_router(route)
      ExtraRouter.new(self, route)
    end

    class ExtraRouter
      def initialize(app, route)
        @app = app
        @route = route
      end

      def handle(&block)
        @route.add_route_action(block)
        self
      end
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
