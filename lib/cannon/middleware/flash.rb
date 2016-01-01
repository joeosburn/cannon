module Cannon
  module Middleware
    class Flash
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        request.define_singleton_method(:flash) do
          @flash ||= Cannon::Flash.new(cookie_jar: request.signed_cookies)
        end

        next_proc.call
      end
    end
  end
end

class Cannon::Flash < Cannon::Session
  def initialize(cookie_jar:)
    super
    @flash = read_cookie
    @session_cookie = {}
    write_cookie
  end

  def [](key)
    @flash[key]
  end
end
