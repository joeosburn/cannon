module Cannon
  module Middleware
    class FlushAndBenchmark
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        response.flush unless response.flushed?
        Cannon.logger.info "Response took #{time_ago_in_ms(request.start_time)}ms" if @app.config.benchmark_requests
      end

    private

      def time_ago_in_ms(time_ago)
        Time.at((Time.now - time_ago)).strftime('%6N').to_i/1000.0
      end
    end
  end
end
