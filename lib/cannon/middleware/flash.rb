module Cannon
  module Middleware
    # Middleware for providing flash on session
    class Flash
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        request.handled? ? next_proc.call : handle(request, response, next_proc)
      end

      private

      def handle(request, _response, next_proc)
        request.define_singleton_method(:flash) do
          @flash ||= Cannon::Flash.new(@app, cookie_jar: request.signed_cookies)
        end

        next_proc.call
      end
    end
  end

  # Flash object which inherits from session
  class Flash < Cannon::Session
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
end
