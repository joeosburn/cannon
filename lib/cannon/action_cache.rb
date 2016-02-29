module Cannon
  class ActionCache
    def initialize(cache:)
      @cache = cache
    end

    def handle_route_action(route_action, request:, response:, next_proc:)
      if request.method == 'GET' && !route_action.action.is_a?(Proc) && cached?(route_action.action)
        run_action_cache(request, response, route_action: route_action)
        next_proc.call
      else
        cached_next_proc = lambda do
          response.delegated_response.stop_recording
          @cache[cache_key(route_action.action)] = response.delegated_response.recording
          next_proc.call
        end
        response.delegated_response.start_recording
        route_action.run_action(request, response, cached_next_proc)
      end
    end

    def delete(action)
      @cache.delete(cache_key(action)) if cached?(action)
    end

    def cached?(action)
      @cache.include? cache_key(action)
    end

    def clear
      @cache.reject! { |k, v| k =~ /^action_cache_/ }
    end

  private

    def run_action_cache(request, response, route_action:)
      @cache[cache_key(route_action.action)].each do |sym, args, block|
        response.delegated_response.send(sym, *args, &block)
      end
    end

    def cache_key(action)
      "action_cache_#{action}"
    end
  end
end
