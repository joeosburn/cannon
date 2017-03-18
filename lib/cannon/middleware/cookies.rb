require 'msgpack'
require 'base64'

module Cannon
  module Middleware
    # Middlware for adding cookie support
    class Cookies
      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        app = @app

        request.define_singleton_method(:cookies) do
          @cookie_jar ||= CookieJar.new(request, response, secret: app.runtime.config[:cookies][:secret])
        end

        request.define_singleton_method(:signed_cookies) do
          @signed_cookie_jar ||= SignedCookieJar.new(request, response, secret: app.runtime.config[:cookies][:secret])
        end

        next_proc.call
      end
    end
  end

  # Cookie jar which reads from a http_cookie value and assigns cookies
  class CookieJar
    def initialize(request, response, secret: nil)
      @request = request
      @response = response
      @secret = secret
      @assigned_cookies = {}
    end

    def [](cookie_name)
      get_assigned_cookie(cookie_name) || get_request_cookie(cookie_name)
    end

    def []=(cookie, value)
      if value.is_a?(Hash)
        assign_cookie(cookie, value)
      else
        assign_cookie(cookie, value: value)
      end
    end

    def delete(cookie)
      assign_cookie(cookie, value: '', max_age: 0, expires: Time.at(0))
    end

    def get_request_cookie(cookie_name)
      cookie = cookies[cookie_name]
      cookie['value'] if cookie
    end

    def get_assigned_cookie(cookie_name)
      @assigned_cookies.dig(cookie_name, :value)
    end

    def cookie_value(cookie_hash)
      escape_cookie_value(::Base64.strict_encode64(cookie_hash.to_msgpack))
    end

    def cookies
      @cookies ||= HttpCookieParser.new(@request.env['HTTP_COOKIE']).parse
    end

    private

    def assign_cookie(cookie, cookie_options)
      @assigned_cookies[cookie] = cookie_options
      @response.cookies(cookie, build_cookie_value(cookie, cookie_options))
    end

    def build_cookie_value(name, cookie_options)
      cookie = "#{name}=#{cookie_value('value' => cookie_options[:value])}"
      cookie << cookie_expires(cookie_options[:expires])
      cookie << cookie_httponly if cookie_options[:httponly] == true
      cookie << cookie_max_age(cookie_options[:max_age])
      cookie
    end

    def cookie_expires(expires)
      expires ? "; Expires=#{expires.httpdate}" : ''
    end

    def cookie_httponly
      '; HttpOnly'
    end

    def cookie_max_age(max_age)
      max_age ? "; Max-Age=#{max_age}" : ''
    end

    def escape_cookie_value(value)
      return value unless value =~ /([\x00-\x20\x7F",;\\])/
      "\"#{value.gsub(/([\\"])/, '\\\\\\1')}\""
    end
  end

  # Signed cookie jar which handles verified cookies
  class SignedCookieJar < CookieJar
    include Signature

    def get_request_cookie(cookie_name)
      cookie = cookies[cookie_name]
      cookie['value'] if cookie && verified_cookie?(cookie_name, cookie)
    end

    def cookie_value(cookie_hash)
      cookie_hash['signature'] = signature(cookie_hash['value'], @secret)
      super(cookie_hash)
    end

    def cookies
      @cookies ||= @request.cookies.cookies.select { |_key, value| value.include? 'signature' }
    end

    private

    def verified_cookie?(name, cookie)
      return true if cookie['verified']

      if signature_match?(cookie)
        cookie['verified'] = true
        true
      else
        cookies.delete(name)
        false
      end
    end

    def signature_match?(cookie)
      cookie['signature'] == signature(cookie['value'], @secret)
    end
  end
end
