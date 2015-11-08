module Cannon
  module Middleware
    class ContentType
      def initialize(app)
        @app = app
      end

      def run(request, response)
        return unless response.headers['Content-Type'] == nil
        response.headers['Content-Type'] = 'text/plain; charset=us-ascii'
      end
    end
  end
end
