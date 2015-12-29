module Cannon
  module Middleware
    class RequestLogger
      def initialize(app)
      end

      def run(request, response, next_proc)
        Cannon.logger.info "#{request.method} #{request.path}"
        next_proc.call
      end
    end
  end
end
