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

    def initialize(wares, request, response)
      @wares = wares
      @request = request
      @response = response
      @index = -1
    end

    attr_reader :wares, :request, :response

    def run
      next_proc = lambda do
        setup_callback
        succeed(request, response)
      end

      if ware = wares[@index += 1]
        ware.run(request, response, next_proc)
      elsif request.handled?
        response.flush
        request.emit('finish', request, response)
      else
        response.not_found
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
