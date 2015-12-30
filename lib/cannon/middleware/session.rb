require 'msgpack'

module Cannon
  module Middleware
    class Session

      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        request.define_singleton_method(:session) do
          @session ||= Cannon::Session.new(cookie_jar: request.signed_cookies)
        end

        next_proc.call
      end
    end
  end
end

class Cannon::Session
  def initialize(cookie_jar:)
    @cookie_jar = cookie_jar
  end

  def [](key)
    session_cookie[key]
  end

  def []=(key, value)
    session_cookie[key] = value
    write_cookie
  end

private

  def session_cookie
    @session_cookie ||= read_cookie
  end

  def write_cookie
    @cookie_jar[Cannon.config.session.cookie_name] = {value: session_cookie.to_msgpack}
  end

  def read_cookie
    cookie = @cookie_jar[Cannon.config.session.cookie_name]
    cookie ? MessagePack.unpack(cookie) : {}
  end
end
