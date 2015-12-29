module Cannon
  module Middleware
    class Cookies

      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        request.define_singleton_method(:cookies) do
          @cookie_jar ||= CookieJar.new(http_cookie: request.http_cookie)
        end

        request.define_singleton_method(:signed_cookies) do
          @signed_cookie_jar ||= CookieJar.new(cookies: request.cookies.with_signatures, signed: true)
        end

        next_proc.call
      end
    end
  end
end
