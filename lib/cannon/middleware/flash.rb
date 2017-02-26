module Cannon
  module Middleware
    # Middleware for providing flash on session
    class Flash
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        app = @app

        request.define_singleton_method(:flash) do
          @flash ||= Cannon::Flash.new(app.runtime.config[:session][:cookie_name], cookie_jar: request.signed_cookies)
        end

        next_proc.call
      end
    end
  end

  # Flash object which inherits from session
  class Flash < Cannon::Session
    def initialize(name, cookie_jar:)
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
