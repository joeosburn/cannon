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

  def get(path)
    path = "/#{path}" unless path =~ /^\//
    uri = URI("http://127.0.0.1:#{PORT}#{path}")
    @response = MockResponse.new(Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      http.request(request)
    end)
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
