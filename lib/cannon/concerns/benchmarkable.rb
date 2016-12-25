# Code for benchmarking code runs
module Benchmarkable
  attr_reader :start_time

private

  def start_benchmarking
    @start_time = Time.now
  end

  def stop_benchmarking
    @stop_time = Time.now
  end

  def benchmark_request(logger:)
    logger.debug "Response took #{benchmark_in_ms}ms"
  end

  def benchmark_in_ms
    Time.at((@stop_time - @start_time)).strftime('%6N').to_i / 1000.0
  end
end
