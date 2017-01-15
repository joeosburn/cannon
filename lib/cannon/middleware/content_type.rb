module Cannon
  module Middleware
    # Middleware which sets a default content type of text/plain if no content type has been set
    class ContentType
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        response.headers['Content-Type'] ? next_proc.call : handle(request, response, next_proc)
      end

      private

      def handle(_request, response, next_proc)
        response.headers['Content-Type'] = 'text/plain; charset=us-ascii'
        next_proc.call
      end
    end
  end
end
