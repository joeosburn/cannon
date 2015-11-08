require 'cannon/middleware/request_logger'
require 'cannon/middleware/files'
require 'cannon/middleware/router'
require 'cannon/middleware/content_type'

module Cannon
  class MiddlewareRunner
    include EventMachine::Deferrable

    def initialize(ware, callback:, app:)
      @app = app
      @ware, @callback = instantiate(ware), callback
    end

    def run(request, response)
      result = @ware.run(request, response)

      if result == false
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
