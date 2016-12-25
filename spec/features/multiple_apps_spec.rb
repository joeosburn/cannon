require 'spec_helper'

RSpec.describe 'Multiple apps at once', :cannon_app do
  before(:each) do
    cannon_app.get('/info') do |request, response|
      response.send('cannon_app info')
    end

    app2 = Cannon::App.new(binding, port: 5032, ip_address: '127.0.0.1')
    app2.runtime.config[:log_level] = :error
    app2.get('/info') do |request, response|
      response.send('app2 info')
    end

    app3 = Cannon::App.new(binding, port: 5033, ip_address: '127.0.0.1')
    app3.runtime.config[:log_level] = :fatal
    app3.config[:middleware] = %w{RequestLogger Files Session Flash Router ContentType}
    app3.get('/info') do |request, response|
      request.cookies
      response.send('app2 info')
    end

    cannon_app.listen(async: true)
    app2.listen(async: true)
    app3.listen(async: true)
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
