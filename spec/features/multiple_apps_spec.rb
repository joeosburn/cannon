require 'spec_helper'

RSpec.describe 'Multiple apps at once', :cannon_app do
  before(:each) do
    cannon_app.get('/info') do |request, response|
      response.send('cannon_app info')
    end

    app2 = Cannon::App.new(binding, port: 5032, ip_address: '127.0.0.1')
    app2.runtime.config.log_level = :error
    app2.get('/info') do |request, response|
      response.send('app2 info')
    end

    cannon_app.listen(async: true)
    app2.listen(async: true)
  end

  it 'allows requests to multiple cannon apps at the same time' do
    get '/info'
    expect(response.body).to eq('cannon_app info')

    get '/info', port: 5032
    expect(response.body).to eq('app2 info')
  end
end
