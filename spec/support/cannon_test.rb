puts 'here we are'

module Cannon::Test
  PORT = 8081

  def cannon_app(&block)
    Thread.abort_on_exception = true
    app = Cannon::App.new(block.binding, middleware: ['RequestLogger', 'Files', 'Router', 'ContentType'])
    yield app
    Thread.new { app.listen(port: PORT) }
    sleep 0.1
  end

  def get(path)
    path = "/#{path}" unless path =~ /^\//
    puts "http://127.0.0.1:#{PORT}#{path}"
    uri = URI("http://127.0.0.1:#{PORT}#{path}")
    @response = Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      http.request(request)
    end
  end

  def response
    @response
  end
end

RSpec.configure do |c|
  c.include Cannon::Test
end
