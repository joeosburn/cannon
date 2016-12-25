require 'msgpack'
require 'base64'

module Cannon
  module Middleware
    class Cookies

      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        return next_proc.call if request.handled?

        request.define_singleton_method(:cookies) do
          @cookie_jar ||= CookieJar.new(request, response)
        end

        request.define_singleton_method(:signed_cookies) do
          @signed_cookie_jar ||= CookieJar.new(
            request, response, cookies: request.cookies.with_signatures, signed: true
          )
        end

        next_proc.call
      end
    end
  end
end

class CookieJar
  include Signature

  class EndOfString < Exception; end

  def initialize(request, response, cookies: nil, signed: false)
    @request = request
    @response = response
    @app = request.app
    @http_cookie = request.http_cookie if cookies.nil?
    @cookies = cookies
    @signed = signed
    @assigned_cookies = {}
  end

  def [](cookie_name)
    get_assigned_cookie(cookie_name) || get_cookie(cookie_name)
  end

  def []=(cookie, value)
    if value.is_a?(Hash)
      assign_cookie(cookie, value)
    else
      assign_cookie(cookie, {value: value})
    end
  end

  def delete(cookie)
    assign_cookie(cookie, {value: '', max_age: 0, expires: Time.at(0)})
  end

  def with_signatures
    cookies.select { |k, v| v.include? 'signature' }
  end

private

  def get_assigned_cookie(cookie_name)
    @assigned_cookies.dig(cookie_name, :value)
  end

  def get_cookie(cookie_name)
    cookie = cookies[cookie_name]
    if cookie
      @signed ? verified_signature(cookie_name, cookie) : cookie['value']
    else
      nil
    end
  end

  def assign_cookie(cookie, cookie_options)
    cookie_options[:signed] = @signed
    @assigned_cookies[cookie] = cookie_options
    @response.cookies(cookie, build_cookie_value(cookie, cookie_options))
  end

  def build_cookie_value(name, cookie_options)
    cookie = "#{name}=#{cookie_value(cookie_options[:value], signed: cookie_options[:signed])}"
    cookie << "; Expires=#{cookie_options[:expires].httpdate}" if cookie_options.include?(:expires)
    cookie << '; HttpOnly' if cookie_options[:httponly] == true
    cookie << "; Max-Age=#{cookie_options[:max_age]}" if cookie_options.include?(:max_age)
    cookie
  end

  def cookies
    @cookies ||= parse_cookies
  end

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
          cookies[name] = MessagePack.unpack(::Base64.strict_decode64(value))
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

  def cookie_value(value, signed:)
    cookie_hash = {'value' => value}
    cookie_hash['signature'] = signature(value) if signed
    escape_cookie_value(::Base64.strict_encode64(cookie_hash.to_msgpack))
  end

  def escape_cookie_value(value)
    return value unless value.match(/([\x00-\x20\x7F",;\\])/)
    "\"#{value.gsub(/([\\"])/, "\\\\\\1")}\""
  end
end
