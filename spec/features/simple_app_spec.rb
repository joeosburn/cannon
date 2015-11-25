require 'spec_helper'

def hi(request, response)
  response.send('hi')
end

def how(request, response)
  response.send(' how ')
end

def are_you(request, response)
  response.send('are you?')
end

def test_view(request, response)
  response.view('test.html')
end

def raise_500(request, response)
  bad_fail_code
end

class World
  def initialize(app)
    @count = 0
  end

  def hello(request, response)
    response.send('Hello World!')
  end

  def count(request, response)
    response.send("count = #{@count}")
    @count += 1
  end
end

RSpec.describe 'Cannon app' do
  before(:all) do
    cannon_app.config.view_path = '../fixtures/views'
    cannon_app.config.public_path = '../fixtures/public'

    cannon_app.get('/hi', action: 'hi')
    cannon_app.get('/how', actions: ['hi', 'how', 'are_you'])
    cannon_app.get('/hello', action: 'World#hello')
    cannon_app.get('/count', action: 'World#count')
    cannon_app.get('/view', action: 'test_view')
    cannon_app.get('/bad', action: 'raise_500')
    cannon_app.get('/inline') do |request, response|
      response.send('inline action')
    end
    cannon_app.get('/value') do |request, response|
      response.send("key = #{request.params[:key]}, place = #{request.params[:place]}")
    end

    cannon_app.get('/resource/:id') do |request, response|
      response.send("id = #{request.params[:id]}")
    end

    cannon_app.get('/:type/by-grouping/:grouping') do |request, response|
      response.send("type=#{request.params[:type]}, grouping=#{request.params[:grouping]}, sort=#{request.params[:sort]}")
    end

    cannon_app.get('/render') do |request, response|
      response.view('render_test.html', name: 'John Calvin')
    end

    cannon_app.post('/hi') do |request, response|
      response.send('created!', status: :created)
    end

    cannon_app.listen(async: true)
  end

  after(:all) { cannon_app.stop }

  describe 'basic get requests' do
    it 'handles a simple action' do
      get '/hi'
      expect(response.code).to be(200)
      expect(response.body).to eq('hi')
    end

    it 'sets the Content-Type' do
      get '/hi'
      expect(response['Content-Type']).to eq('text/plain; charset=us-ascii')
    end

    it 'sets the Content-Length' do
      get '/how'
      expect(response['Content-Length']).to eq('15')
    end

    it 'handles an action chain' do
      get '/how'
      expect(response.code).to be(200)
      expect(response.body).to eq('hi how are you?')
    end

    it 'handles inline actions' do
      get '/inline'
      expect(response.code).to be(200)
      expect(response.body).to eq('inline action')
    end

    it 'handles query params' do
      get '/value', place: 123, key: 'a value', place: '12 ave st'
      expect(response.body).to eq('key = a value, place = 12 ave st')
    end

    it 'handles params in routes' do
      get '/resource/12'
      expect(response.body).to eq('id = 12')
      get '/messages/by-grouping/author', sort: 'name'
      expect(response.body).to eq('type=messages, grouping=author, sort=name')
    end

    it 'renders a view' do
      get '/view'
      expect(response.body).to eq('Test view content')
      expect(response.code).to be(200)
      expect(response['Content-Type']).to eq('text/html')
    end

    it 'serves files' do
      get '/background.jpg'
      expect(response.body.size).to_not eq('')
      expect(response.code).to be(200)
      expect(response['Content-Type']).to eq('image/jpeg')
      expect(response['Content-Length']).to eq('55697')
    end

    it 'handles full paths for view_path and public_path' do
      cannon_app.config.view_path = Cannon.root + '/../fixtures/views'
      cannon_app.config.public_path = Cannon.root + '/../fixtures/public'
      get '/background.jpg'
      expect(response.code).to be(200)
      get '/view'
      expect(response.code).to be(200)
    end

    it 'returns 404 for not found routes' do
      get '/badroute'
      expect(response.code).to be(404)
    end

    it 'returns 500 for errors' do
      old_log_level = Cannon.config.log_level
      Cannon.config.log_level = :fatal
      get '/bad'
      expect(response.code).to be(500)
      Cannon.config.log_level = old_log_level
    end

    it 'handles controller based actions' do
      get '/hello'
      expect(response.body).to eq('Hello World!')
      expect(response.code).to eq(200)
    end

    it 'keeps the instantiation of the controller' do
      get '/count'
      expect(response.body).to eq('count = 0')
      get '/count'
      expect(response.body).to eq('count = 1')
      get '/count'
      expect(response.body).to eq('count = 2')
    end

    it 'does mustache based rendering' do
      get '/render'
      expect(response.body).to eq('Hello John Calvin')
    end

    it 'handles post requests' do
      post '/hi'
      expect(response.body).to eq('created!')
      expect(response.code).to eq(201)
    end
  end
end
