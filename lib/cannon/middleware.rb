require 'cannon/middleware/flush_and_benchmark'
require 'cannon/middleware/request_logger'
require 'cannon/middleware/files'
require 'cannon/middleware/router'
require 'cannon/middleware/content_type'
require 'cannon/middleware/cookies'
require 'cannon/middleware/session'
require 'cannon/middleware/flash'

module Cannon
  class MiddlewareRunner
    include EventMachine::Deferrable

    def initialize(ware, callback:, app:)
      @app = app
      @ware, @callback = instantiate(ware), callback
    end

    def run(request, response)
      next_proc = -> do
        setup_callback
        self.succeed(request, response)
      end

      result = @ware.run(request, response, next_proc)
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
