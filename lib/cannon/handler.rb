module Cannon
  class Handler < EventMachine::Connection
    include EventMachine::HttpServer

    def app
      # magically defined by Cannon::App
      self.class.app
    end

    def process_http_request
      app.reload_environment if Cannon.env == 'development'
      
      request = Request.new(self)
      response = Response.new(self)

      EM.defer(
        -> { middleware_runner.run(request, response) if middleware? },
        ->(result) { handle_route(request, response) unless response.sent? }
      )
    end

  private

    def handle_route(request, response)
      matched_route = app.routes.find { |route| route.matches? request.path }
      matched_route.nil? ? response.not_found : matched_route.handle(request, response)
    end

    def middleware?
      app.middleware.size > 0
    end

    def middleware_runner
      @middleware_runner ||= build_middleware_runner(app.middleware.dup)
    end

    def build_middleware_runner(middleware, callback: nil)
      return callback if middleware.size < 1

      middleware_runner = MiddlewareRunner.new(middleware.pop, callback: callback, app: app)
      build_middleware_runner(middleware, callback: middleware_runner)
    end
  end

  class MiddlewareRunner
    include EventMachine::Deferrable

    def initialize(ware, callback:, app:)
      @app = app
      @ware, @callback = instantiate(ware), callback
    end

    def run(request, response)
      @ware.run(request, response)

      if response.sent?
        self.fail
      else
        setup_callback
        self.succeed(request, response)
      end
    end

  private

    def setup_callback
      set_deferred_status nil
      callback do |request, response|
        @callback.run(request, response) unless @callback.nil?
      end
    end

    def instantiate(ware)
      if ware.is_a?(String)
        begin
          Object.const_get(ware).new(@app)
        rescue NameError
          Object.const_get("Cannon::Middleware::#{ware}").new(@app)
        end
      else
        ware.new(@app)
      end
    end
  end
end
