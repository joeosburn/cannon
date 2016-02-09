module ActionCaching
private
  def run_action(request, response, next_proc)
    if request.method == 'GET' && !action.is_a?(Proc) && action_cached?(request)
      run_action_cache(request, response)
      next_proc.call
    else
      cached_next_proc = lambda do
        response.delegated_response.stop_recording
        app.cache[action_cache_key(request)] = response.delegated_response.recording
        next_proc.call
      end
      response.delegated_response.start_recording
      super(request, response, cached_next_proc)
    end
  end

  def action_cached?(request)
    app.cache.include? action_cache_key(request)
  end

  def run_action_cache(request, response)
    app.cache[action_cache_key(request)].each do |sym, args, block|
      response.delegated_response.send(sym, *args, &block)
    end
  end

  def action_cache_key(request)
    "action_cache_#{request.path}_#{action}"
  end
end
