
module Cannon
  # Class for parsing http cookies
  class HttpCookieParser
    # Error raised when end of string hit; used for flow control
    class EndOfString < Exception; end

    def initialize(http_cookie)
      @http_cookie = http_cookie
    end

    def parse
      cookies = {}

      return cookies if @http_cookie.empty?

      begin
        pos = 0
        loop do
          pos = read_whitespace(@http_cookie, pos)
          name, pos = read_cookie_name(@http_cookie, pos)
          value, pos = read_cookie_value(@http_cookie, pos)
          begin
            cookies[name] = MessagePack.unpack(::Base64.strict_decode64(value))
          rescue StandardError; end
        end
      rescue EndOfString
      end

      cookies
    end

  private

    def read_whitespace(cookie, pos)
      raise EndOfString if cookie[pos] == nil
      pos = pos + 1 while cookie[pos] == ' ' && pos < cookie.length
      pos
    end

    def read_cookie_name(cookie, pos)
      start_pos = pos
      pos = pos + 1 while !['=', nil].include?(cookie[pos])
      return cookie[start_pos..(pos - 1)], pos + 1
    end

    def read_cookie_value(cookie, pos)
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
  end
end
