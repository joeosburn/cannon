module Cannon
  module Middleware
    class RequestLogger
      def initialize(app)
      end

      def run(request, response)
        Cannon.logger.info "#{request.http_method} #{request.path}"
      end
    end
  end
end
