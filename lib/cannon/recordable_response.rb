module Cannon
  # RecordableResponse is delegated response than can record all of its method calls and
  # provide them as a recording to be played back later.
  class RecordableResponse
    attr_reader :headers

    def initialize(response)
      @response = response
      @recording = false
      @headers = {}
      @cookies = {}
    end

    def start_recording
      method_stack.clear
      @recording = true
    end

    def stop_recording
      @recording = false
    end

    def recording?
      @recording
    end

    def recording
      method_stack
    end

    def header(key, value)
      method_stack << [:header, [key, value], nil]
      @headers[key] = value
    end

    def cookies(key, value)
      method_stack << [:cookies, [key, value], nil]
      @cookies[key] = value
      header('Set-Cookie', @cookies.collect { |_key, cookie_value| cookie_value })
    end

    def flush
      @response.headers = headers
      @response.flush
    end

    def method_missing(sym, *args, &block)
      method_stack << [sym, args, block] if recording?
      @response.send(sym, *args, &block)
    end

    def respond_to_missing?(method_name, _include_private = false)
      @response.respond_to?(method_name)
    end

    private

    def method_stack
      @method_stack ||= []
    end
  end
end
