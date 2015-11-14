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
  PORT = 8081

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

end

RSpec.configure do |c|
  c.include Cannon::Test
end
