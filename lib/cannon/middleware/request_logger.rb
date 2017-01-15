module Cannon
  module Middleware
    # Middleware to log requests
    class RequestLogger
      def initialize(app)
        @app = app
      end

      def run(request, _response, next_proc)
        @app.logger.info request
        next_proc.call
      end
    end
  end
end
