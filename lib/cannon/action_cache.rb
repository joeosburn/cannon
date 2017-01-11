module Cannon
  # ActionCache handles basic caching for GET requests.
  class ActionCache
    attr_reader :route_action, :cache

    def initialize(route_action, cache:)
      @route_action = route_action
      @cache = cache
    end

    def run_action(request, response, next_proc)
      if cached?
        run_action_cache(request, response)
        next_proc.call
      else
        response.delegated_response.start_recording
        route_action.run_action(request, response, end_recording_proc(response, next_proc))
      end
    end

    def delete
      cache.delete(cache_key) if cached?
    end

    def cached?
      cache.include? cache_key
    end

    private

    def end_recording_proc(response, next_proc)
      lambda do
        response.delegated_response.stop_recording
        write_cache_value(response)
        next_proc.call
      end
    end

    def write_cache_value(response)
      cache[cache_key] = response.delegated_response.recording
    end

    def run_action_cache(_request, response)
      cache[cache_key].each do |sym, args, block|
        response.delegated_response.send(sym, *args, &block)
      end
    end

    def cache_key
      "action_cache_#{route_action.action}"
    end
  end
end
