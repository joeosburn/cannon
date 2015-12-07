module Cannon
  module Middleware
    class Cookies
      class EndOfString < Exception; end

      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        install_cookies(request)
        next_proc.call
      end

    private

      def install_cookies(request)
        read_whitespace = ->(cookie, pos) do
          raise EndOfString if cookie[pos] == nil
          pos = pos + 1 while cookie[pos] == ' ' && pos < cookie.length
          pos
        end

        read_cookie_name = ->(cookie, pos) do
          start_pos = pos
          pos = pos + 1 while !['=', nil].include?(cookie[pos])
          return cookie[start_pos..(pos - 1)], pos + 1
        end

        read_cookie_value = ->(cookie, pos) do
          in_quotes = false
          pos = pos + 1 and in_quotes = true if cookie[pos] == '"'
          start_pos = pos

          if in_quotes
            pos = pos + 1 while pos < cookie.length && !(cookie[pos] == '"' && cookie[pos - 1] != '\\')
            value = cookie[start_pos..(pos - 1)].gsub("\\\"", '"')
            pos = pos + 1 while ![';', nil].include?(cookie[pos])
          else
            pos = pos + 1 while ![';', nil].include?(cookie[pos])
            value = cookie[start_pos..(pos - 1)]
          end

          return value, pos + 1
        end

        request.define_singleton_method(:cookies) do
          @cookies ||= -> do
            cookies = {}

            begin
              pos = 0
              loop do
                pos = read_whitespace.call(request.http_cookie, pos)
                name, pos = read_cookie_name.call(request.http_cookie, pos)
                value, pos = read_cookie_value.call(request.http_cookie, pos)
                cookies[name.to_sym] = value
              end
            rescue EndOfString
            end unless request.http_cookie.nil?

            cookies
          end.call
        end
      end
    end
  end
end
