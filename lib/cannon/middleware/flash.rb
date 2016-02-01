module Cannon
  module Middleware
    class Flash
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        return next_proc.call if request.handled?

        request.define_singleton_method(:flash) do
          @flash ||= Cannon::Flash.new(request.app, cookie_jar: request.signed_cookies)
        end

        next_proc.call
      end
    end
  end
end

class Cannon::Flash < Cannon::Session
  def initialize(app, cookie_jar:)
    super
    @flash = read_cookie
    @session_cookie = {}
    write_cookie
  end

  def [](key)
    @flash[key]
  end
end
