require 'http-cookie'

class MockResponse
  def initialize(response)
    @response = response
  end

  def code
    @response.code.to_i
  end

  def headers
    @headers ||= build_headers
  end

  def method_missing(sym, *args, &block)
    @response.send(sym, *args, &block)
  end

private

  def build_headers
    headers = {}
    each_header { |k, v| headers[k] = v }
    headers
  end
end

module Cannon::Test
  PORT = 5031

  def cannon_app
    @cannon_app ||= create_cannon_app
  end

  def get(path, params = {})
    http_request(path, Net::HTTP::Get, query_params: params)
  end

  def post(path, params = {})
    http_request(path, Net::HTTP::Post, post_params: params)
  end

  def put(path, params = {})
    http_request(path, Net::HTTP::Put, post_params: params)
  end

  def patch(path, params = {})
    http_request(path, Net::HTTP::Patch, post_params: params)
  end

  def delete(path, params = {})
    http_request(path, Net::HTTP::Delete, post_params: params)
  end

  def head(path, params = {})
    http_request(path, Net::HTTP::Head, query_params: params)
  end

  def response
    @response
  end

  def cookies
    jar.inject({}) { |cookies, cookie| cookies[cookie.name] = cookie; cookies }
  end

  def jar
    @jar ||= HTTP::CookieJar.new
  end

private

  def http_request(path, request_class, post_params: nil, query_params: nil)
    uri = URI("http://127.0.0.1:#{PORT}#{path}")
    uri.query = URI.encode_www_form(query_params) unless query_params.nil?
    req = request_class.new(uri)
    req.set_form_data(post_params) unless post_params.nil?
    req['Cookie'] = HTTP::Cookie.cookie_value(jar.cookies(uri)) unless jar.empty?

    @response = MockResponse.new(Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end)

    if @response['Set-Cookie']
      @response.get_fields('Set-Cookie').each do |cookie|
        jar.parse(cookie, uri)
      end
    end
  end

  def create_cannon_app
    app = Cannon::App.new(binding, port: PORT, ip_address: '127.0.0.1')
    app.config.log_level = :error
    app.config.cookies.secret = 'test'
    app
  end
end

RSpec.configure do |config|
  config.include Cannon::Test

  config.append_after(:context, cannon_app: true) do
    cannon_app.stop
    @cannon_app = nil
    jar.clear
  end
end
