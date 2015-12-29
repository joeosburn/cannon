module Cannon
  module Middleware
    class ContentType
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        return next_proc.call unless response.headers['Content-Type'].nil?
        response.headers['Content-Type'] = 'text/plain; charset=us-ascii'
        next_proc.call
      end
    end
  end
end
