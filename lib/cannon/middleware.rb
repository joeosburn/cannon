require 'cannon/middleware/request_logger'
require 'cannon/middleware/files'
require 'cannon/middleware/router'
require 'cannon/middleware/content_type'
require 'cannon/middleware/cookies'
require 'cannon/middleware/session'
require 'cannon/middleware/flash'
require 'cannon/middleware/benchmark'

module Cannon
  # Runs the middlewares in deferrable form
  class MiddlewareRunner
    include EventMachine::Deferrable

    attr_reader :ware

    def initialize(ware_name, callback:, app:)
      @app = app
      @ware = app.middleware[ware_name]
      @callback = callback
    end

    def run(request, response)
      next_proc = lambda do
        setup_callback
        succeed(request, response)
      end

      ware.run(request, response, next_proc)
    end

    private

    def setup_callback
      set_deferred_status nil
      callback do |request, response|
        if @callback
          @callback.run(request, response)
        elsif request.handled?
          response.flush
          request.emit('finish', request, response)
        end
      end
    end
  end

  # Holds the middlewares in a hash accessible by name and handles instantation
  class Middlewares
    def initialize(app)
      @wares = Hash.new { |wares, name| wares[name] = instantiate(name) }
      @app = app
    end

    def [](name)
      @wares[name]
    end

    private

    def instantiate(ware_name)
      if ware_name.is_a?(String)
        begin
          Object.const_get(ware_name).new(@app)
        rescue NameError
          Object.const_get("Cannon::Middleware::#{ware_name}").new(@app)
        end
      else
        ware_name.new(@app)
      end
    end
  end

  # App code for middleware support
  module AppMiddleware
    def middleware
      @middleware ||= Middlewares.new(self)
    end

    def handle(request, response)
      super
      middleware_runner.run(request, response) if run_middleware?(request)
    end

    private

    def run_middleware?(request)
      !request.handled? && !config[:middleware].empty?
    end

    def middleware_runner
      @middleware_runner ||= build_middleware_runner
    end

    def prepared_middleware_stack
      config[:middleware].dup
    end

    def build_middleware_runner(middleware = prepared_middleware_stack, callback: nil)
      return callback if middleware.empty?

      middleware_runner = MiddlewareRunner.new(middleware.pop, callback: callback, app: self)
      build_middleware_runner(middleware, callback: middleware_runner)
    end
  end
end

Cannon::App.prepend Cannon::AppMiddleware
