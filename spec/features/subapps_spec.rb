require 'spec_helper'

RSpec.describe 'Subapps', :cannon_app do
  before(:each) do
    admin_app = Cannon::App.new(binding)
    admin_app.get('/login') do |request, response|
      response.send('Send your login info')
    end
    admin_app.post('/login') do |request, response|
      response.send("logged in as #{request.params[:username]}")
    end
    cannon_app.mount(admin_app, at: '/admin')

    cannon_app.get('/info') do |request, response|
      response.send('Main Info')
    end

    cannon_app.get('/admin/info') do |request, response|
      response.send('Admin Info')
    end

    cannon_app.listen(async: true)
  end

  it 'mounts the subapp at the given location' do
    get '/admin/login'
    expect(response.body).to eq('Send your login info')
    post '/admin/login', username: 'joe'
    expect(response.body).to eq('logged in as joe')
  end

  it 'allows normal requests to go through' do
    get '/info'
    expect(response.body).to eq('Main Info')
  end

  it 'allows normal requests at a subapp mounting point' do
    get '/admin/info'
    expect(response.body).to eq('Admin Info')
  end
end
