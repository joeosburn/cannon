require 'msgpack'

module Cannon
  class CookieJar
    include Signature

    class EndOfString < Exception; end

    def initialize(http_cookie: nil, cookies: nil, signed: false)
      @http_cookie = http_cookie
      @cookies = cookies
      @signed = signed

      self.define_singleton_method(:signed) do
        @signed_cookies ||= CookieJar.new(cookies: cookies_with_signatures, signed: true)
      end if !@signed
    end

    def [](cookie_name)
      cookie = cookies[cookie_name]
      if cookie
        @signed ? verified_signature(cookie_name, cookie) : cookie['value']
      else
        nil
      end
    end

  private

    def verified_signature(name, cookie)
      return cookie['value'] if cookie['verified']

      if cookie['signature'] == signature(cookie['value'])
        cookie['verified'] = true
        cookie['value']
      else
        cookies.delete(name)
        nil
      end
    end

    def cookies_with_signatures
      cookies.select { |k, v| v.include? 'signature' }
    end

    def cookies
      @cookies ||= parse_cookies
    end

    def parse_cookies
      cookies = {}
      return cookies if @http_cookie.nil? || @http_cookie == ''

      begin
        pos = 0
        loop do
          pos = read_whitespace(@http_cookie, pos)
          name, pos = read_cookie_name(@http_cookie, pos)
          value, pos = read_cookie_value(@http_cookie, pos)
          begin
            cookies[name.to_sym] = MessagePack.unpack(value)
          rescue StandardError; end
        end
      rescue EndOfString
      end

      cookies
    end

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
