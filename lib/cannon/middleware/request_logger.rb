module Cannon
  module Middleware
    class RequestLogger
      def initialize(app)
      end

      def run(request, response)
        puts "#{request.http_method} #{request.path}"
      end
    end
  end
end
