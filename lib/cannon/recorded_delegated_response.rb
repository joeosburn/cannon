module Cannon
  # RecordedDelegatedResponse is delegated response than can record all of its method calls and
  # provide them as a recording to be played back later.
  class RecordedDelegatedResponse
    attr_reader :headers

    def initialize(http_server)
      @delegated_response = EventMachine::DelegatedHttpResponse.new(http_server)
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

    def send_headers
      @delegated_response.headers = headers
    end

    def method_missing(sym, *args, &block)
      method_stack << [sym, args, block] if recording?
      @delegated_response.send(sym, *args, &block)
    end

    private

    def method_stack
      @method_stack ||= []
    end
  end
end
