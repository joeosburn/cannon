require 'cannon/middleware/request_logger'
require 'cannon/middleware/files'
require 'cannon/middleware/router'
require 'cannon/middleware/cookies'
require 'cannon/middleware/session'
require 'cannon/middleware/flash'
require 'cannon/middleware/benchmark'
require 'cannon/middleware/subapp'

module Cannon
  # Runs the middlewares in deferrable form
  class MiddlewareRunner
    include EventMachine::Deferrable

    def initialize(wares, request, response, finish_proc)
      @wares = wares
      @request = request
      @response = response
      @finish_proc = finish_proc
      @index = -1
    end

    attr_reader :wares, :request, :response

    def run
      next_proc = lambda do
        setup_callback
        succeed(request, response)
      end

      if request.handled?
        response.flush
        request.emit('finish', request, response)
      elsif ware = wares[@index += 1]
        ware.run(request, response, next_proc)
      else
        @finish_proc.call
      end
    end

    private

    def setup_callback
      set_deferred_status nil
      callback { |request, response| run }
    end
  end

  # Holds instantiated middlewares
  class Middlewares
    def initialize(app, wares)
      @app = app
      @wares = wares.map { |name| instantiate(name) }
    end

    def each(&block)
      @wares.each { |w| yield w }
    end

    def [](index)
      @wares[index]
    end

    def unshift(ware)
      @wares.unshift(instantiate(ware))
    end

    def push(ware)
      @wares.push(instantiate(ware))
    end

    def size
      @wares.size
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
end
