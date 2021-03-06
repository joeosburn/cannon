require 'msgpack'

module Cannon
  module Middleware
    # Middleware for handling the session
    class Session
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        app = @app

        request.define_singleton_method(:session) do
          @session ||= Cannon::Session.new(app.runtime.config[:session][:cookie_name], cookie_jar: signed_cookies)
        end

        next_proc.call
      end
    end
  end

  # Holds the request session
  class Session
    def initialize(name, cookie_jar:)
      @name = name
      @cookie_jar = cookie_jar
    end

    def [](key)
      session_cookie[key]
    end

    def []=(key, value)
      session_cookie[key] = value
      write_cookie
    end

    def delete(key)
      session_cookie.delete(key)
      write_cookie
    end

    def clear
      session_cookie.clear
      write_cookie
    end

    private

    def session_cookie
      @session_cookie ||= read_cookie
    end

    def write_cookie
      @cookie_jar[@name] = { value: session_cookie.to_msgpack }
    end

    def read_cookie
      cookie = @cookie_jar[@name]
      cookie ? MessagePack.unpack(cookie) : {}
    end
  end
end
