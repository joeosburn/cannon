class MockResponse
  def initialize(response)
    @response = response
  end

  def code
    @response.code.to_i
  end

  def headers
    @response
  end

  def method_missing(sym, *args, &block)
    @response.send(sym, *args, &block)
  end
end

module Cannon::Test
  PORT = 5031

  def cannon_app
    @cannon_app ||= create_cannon_app
  end

  def get(path, params = {})
    uri = URI("http://127.0.0.1:#{PORT}#{path}")
    uri.query = URI.encode_www_form(params)
    @response = MockResponse.new(Net::HTTP.get_response(uri))
  end

  def post(path, params = {})
    post_request(path, Net::HTTP::Post, params)
  end

  def put(path, params = {})
    post_request(path, Net::HTTP::Put, params)
  end

  def patch(path, params = {})
    post_request(path, Net::HTTP::Patch, params)
  end

  def delete(path, params = {})
    post_request(path, Net::HTTP::Delete, params)
  end

  def head(path, params = {})
    path = "#{path}?#{URI.encode_www_form(params)}" if params.count > 0
    Net::HTTP.start('127.0.0.1', PORT) do |http|
      @response = MockResponse.new(http.head(path))
    end
  end

  def response
    @response
  end

private

  def post_request(path, request_class, params)
    uri = URI("http://127.0.0.1:#{PORT}#{path}")
    req = request_class.new(uri)
    req.set_form_data(params)
    @response = MockResponse.new(Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end)
  end

  def create_cannon_app
    app = Cannon::App.new(binding, port: PORT, ip_address: '127.0.0.1')
    app.config.log_level = :error
    app
  end

end

RSpec.configure do |c|
  c.include Cannon::Test
end
