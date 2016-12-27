require 'spec_helper'

RSpec.describe 'Multiple apps at once', :cannon_app do
  let(:app2) do
    app = Cannon::App.new(binding, port: 5032, ip_address: '127.0.0.1')
    app.runtime.config[:log_level] = :error
    start_cannon_server(app)
    app
  end

  let(:app3) do
    app = Cannon::App.new(binding, port: 5033, ip_address: '127.0.0.1')
    app.runtime.config[:log_level] = :fatal
    app.config[:middleware] = %w{RequestLogger Files Session Flash Router ContentType}
    start_cannon_server(app)
    app
  end

  before do
    cannon_app.get('/info') do |request, response|
      response.send('cannon_app info')
    end

    app2.get('/info') do |request, response|
      response.send('app2 info')
    end

    app3.get('/info') do |request, response|
      request.cookies
      response.send('app2 info')
    end
  end

  after do
    stop_cannon_server(app2)
    stop_cannon_server(app3)
  end

  it 'allows requests to multiple cannon apps at the same time' do
    get '/info'
    expect(response.body).to eq('cannon_app info')

    get '/info', port: 5032
    expect(response.body).to eq('app2 info')
  end

  it 'allows each app to have their own config' do
    get '/info', port: 5033
    expect(response.code).to be(500) # confirm cookies middleware is not present
  end
end
