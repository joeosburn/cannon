class MockResponse
  def initialize(response)
    @response = response
  end

  def code
    @response.code.to_i
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
    uri = URI("http://127.0.0.1:#{PORT}#{path}")
    @response = MockResponse.new(Net::HTTP.post_form(uri, params))
  end

  def response
    @response
  end

private

  def create_cannon_app
    app = Cannon::App.new(binding, port: PORT, ip_address: '127.0.0.1')
    app.config.log_level = :error
    app
  end

end

RSpec.configure do |c|
  c.include Cannon::Test
end
