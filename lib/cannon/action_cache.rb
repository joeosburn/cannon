module Cannon
  class ActionCache
    def initialize(cache:)
      @cache = cache
    end

    def handle_route_action(route_action, request:, response:, next_proc:)
      if request.method == 'GET' && !route_action.action.is_a?(Proc) && cached?(route_action)
        run_action_cache(request, response, route_action: route_action)
        next_proc.call
      else
        cached_next_proc = lambda do
          response.delegated_response.stop_recording
          @cache[cache_key(route_action)] = response.delegated_response.recording
          next_proc.call
        end
        response.delegated_response.start_recording
        route_action.run_action(request, response, cached_next_proc)
      end
    end

    def cached?(route_action)
      @cache.include? cache_key(route_action)
    end

  private

    def run_action_cache(request, response, route_action:)
      @cache[cache_key(route_action)].each do |sym, args, block|
        response.delegated_response.send(sym, *args, &block)
      end
    end

    def cache_key(route_action)
      "action_cache_#{route_action.action}"
    end
  end
end
