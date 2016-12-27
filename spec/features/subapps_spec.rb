require 'spec_helper'

RSpec.describe 'Subapps', :cannon_app do
  before do
    admin_app = Cannon::App.new(binding)
    admin_app.get('/login') do |request, response|
      response.send('Send your login info')
    end
    admin_app.post('/login') do |request, response|
      response.send("logged in as #{request.params[:username]}")
    end
    cannon_app.mount(admin_app, at: '/admin')

    resources_app = Cannon::App.new(binding)
    resources_app.get('/') do |request, response|
      response.send('resources admin')
    end
    admin_app.mount(resources_app, at: '/resources')

    catalog_app = Cannon::App.new(binding)
    catalog_app.get('/') do |request, response|
      response.send('catalog index')
    end
    cannon_app.mount(catalog_app, at: '/library')

    cannon_app.get('/info') do |request, response|
      response.send('Main Info')
    end

    cannon_app.get('/admin/info') do |request, response|
      response.send('Admin Info')
    end
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

  it 'allows mounting of apps within apps' do
    get '/admin/resources/'
    expect(response.body).to eq('resources admin')
  end

  it 'allows mounting multiple apps' do
    get '/library/'
    expect(response.body).to eq('catalog index')
  end
end
