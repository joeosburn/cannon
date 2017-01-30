require 'http-cookie'

# A mocked http response object suitable for testing
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
    each_header { |key, value| headers[key] = value }
    headers
  end
end

module Cannon
  # Basic module for providing cannon app test support
  module Test
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
      head:   :query
    }.each do |http_method, params_type|
      define_method(http_method) do |path, port: DEFAULT_PORT, **params|
        http_request(path, Net::HTTP.const_get(http_method.capitalize, false), :port => port, params_type => params)
      end
    end

    def cookies
      jar.each_with_object({}) do |cookie, cookies|
        cookies[cookie.name] = cookie
        cookies
      end
    end

    def jar
      @jar ||= HTTP::CookieJar.new
    end

    def start_cannon_server(app, port: DEFAULT_PORT, ip_address: '127.0.0.1')
      cannon_servers[app] = Cannon::Server.start_async(app, port: port, ip_address: ip_address)
    end

    def stop_cannon_server(app)
      cannon_servers[app].stop
    end

    private

    def cannon_servers
      @cannon_servers ||= {}
    end

    def http_request(path, request_class, options = {})
      uri = build_uri("http://127.0.0.1:#{options[:port]}#{path}", options[:query])
      req = build_req(uri, request_class, options[:post])

      @response = MockResponse.new(Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) })

      handle_response_cookies(uri)
    end

    def build_uri(url, query)
      URI(url).tap { |uri| uri.query = URI.encode_www_form(query) if query }
    end

    def build_req(uri, request_class, post)
      request_class.new(uri).tap do |req|
        req.set_form_data(post) if post
        req['Cookie'] = HTTP::Cookie.cookie_value(jar.cookies(uri)) unless jar.empty?
      end
    end

    def handle_response_cookies(uri)
      return unless @response['Set-Cookie']

      @response.get_fields('Set-Cookie').each do |cookie|
        jar.parse(cookie, uri)
      end
    end

    def start_cannon_app
      Cannon::App.new.tap do |app|
        default_runtime_config(app.runtime.config)
        default_app_config(app.config)
        start_cannon_server(app)
      end
    end

    def default_runtime_config(config)
      config[:log_level] = :error
      config[:cookies][:secret] = 'test'
    end

    def default_app_config(config)
      config[:view_path] = '../fixtures/views'
      config[:public_path] = '../fixtures/public'
    end
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
