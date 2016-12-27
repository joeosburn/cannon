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
  attr_reader :response

  DEFAULT_PORT = 5031

  def cannon_app
    @cannon_app ||= start_cannon_app
  end

  {
    get:    :query,
    post:   :post,
    put:    :post,
    patch:  :post,
    delete: :post,
    head:   :query,
  }.each do |http_method, params_type|
    define_method(http_method) do |path, port: DEFAULT_PORT, **params|
      http_request(path, Net::HTTP.const_get(http_method.capitalize, false), :port => port, params_type => params)
    end
  end

  def cookies
    jar.inject({}) { |cookies, cookie| cookies[cookie.name] = cookie; cookies }
  end

  def jar
    @jar ||= HTTP::CookieJar.new
  end

  def start_cannon_server(app)
    cannon_servers[app] = Cannon::Server.start_async(app)
  end

  def stop_cannon_server(app)
    cannon_servers[app].stop
  end

private

  def cannon_servers
    @cannon_servers ||= {}
  end

  def http_request(path, request_class, port:, post: nil, query: nil)
    uri = URI("http://127.0.0.1:#{port}#{path}")
    uri.query = URI.encode_www_form(query) unless query.nil?
    req = request_class.new(uri)
    req.set_form_data(post) unless post.nil?
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

  def start_cannon_app
    app = Cannon::App.new(binding, port: DEFAULT_PORT, ip_address: '127.0.0.1')
    app.runtime.config[:log_level] = :error
    app.runtime.config[:cookies][:secret] = 'test'
    app.config[:view_path] = '../fixtures/views'
    app.config[:public_path] = '../fixtures/public'
    start_cannon_server(app)
    app
  end
end

RSpec.configure do |config|
  config.include Cannon::Test

  config.append_after(:each, cannon_app: true) do
    stop_cannon_server(cannon_app)
  end

  config.append_before(:each, cannon_app: true) do
    @cannon_app = nil
    jar.clear
    Cannon.instance_variable_set('@env', nil)
    Cannon.instance_variable_set('@config', nil)
    cannon_app
  end
end
