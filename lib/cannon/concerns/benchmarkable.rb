# Code for benchmarking code runs
module Benchmarkable
  def start_benchmarking
    @benchmark_start_time = Time.now
  end

  def benchmark_request(logger:)
    logger.debug "Response took #{benchmark_in_ms}ms"
  end
  
  private

  attr_reader :benchmark_start_time

  def benchmark_in_ms
    Time.at((Time.now - benchmark_start_time)).strftime('%6N').to_i / 1000.0
  end
end
