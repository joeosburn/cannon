module Cannon
  module Middleware
    # Middlware for benchmarking requests
    class Benchmark
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        request.on('finish') do |request, response|
          time_in_ms = Time.at((Time.now - request.env['start-time'])).strftime('%6N').to_i / 1000.0
          request.app.logger.debug "Response took #{time_in_ms}ms"
        end

        next_proc.call
      end
    end
  end
end
