require 'spec_helper'

def hi(request, response, next_proc)
  response.send('hi')
  next_proc.call
end

def how(request, response, next_proc)
  response.send(' how ')
  next_proc.call
end

def are_you(request, response, next_proc)
  response.send('are you?')
  next_proc.call
end

def test_view(request, response, next_proc)
  response.view('test.html')
  next_proc.call
end

def raise_500(request, response, next_proc)
  bad_fail_code
end

class World
  def initialize(app)
    @count = 0
  end

  def hello(request, response, next_proc)
    response.send('Hello World!')
    next_proc.call
  end

  def count(request, response, next_proc)
    response.send("count = #{@count}")
    @count += 1
    next_proc.call
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
    cannon_app.get('/inline') do |request, response, next_proc|
      response.send('inline action')
      next_proc.call
    end
    cannon_app.get('/value') do |request, response, next_proc|
      response.send("key = #{request.params[:key]}, place = #{request.params[:place]}")
      next_proc.call
    end

    cannon_app.get('/resource/:id') do |request, response, next_proc|
      response.send("id = #{request.params[:id]}")
      next_proc.call
    end

    cannon_app.get('/:type/by-grouping/:grouping') do |request, response, next_proc|
      response.send("type=#{request.params[:type]}, grouping=#{request.params[:grouping]}, sort=#{request.params[:sort]}")
      next_proc.call
    end

    cannon_app.get('/render') do |request, response, next_proc|
      response.view('render_test.html', name: 'John Calvin')
      next_proc.call
    end

    cannon_app.post('/hi') do |request, response, next_proc|
      response.send('created!', status: :created)
      next_proc.call
    end

    cannon_app.post('/submit') do |request, response, next_proc|
      response.send("name=#{request.params[:name]}, age=#{request.params[:age]}")
      next_proc.call
    end

    cannon_app.patch('/update') do |request, response, next_proc|
      response.send("updated object #{request.params[:name]}")
      next_proc.call
    end

    cannon_app.put('/modify') do |request, response, next_proc|
      response.send("modified object #{request.params[:name]}")
      next_proc.call
    end

    cannon_app.get('/object/:id') do |request, response, next_proc|
      response.send("view #{request.params[:id]}")
      next_proc.call
    end

    cannon_app.delete('/object/:id') do |request, response, next_proc|
      response.send("deleted #{request.params[:id]}")
      next_proc.call
    end

    cannon_app.head('/object/:id') do |request, response, next_proc|
      response.header('ETag', "object_#{request.params[:id]}")
      response.send('head body should be ignored')
      next_proc.call
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
      get '/value', key: 'a value', place: '12 ave st'
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

    it 'handles post params' do
      post('/submit', name: 'John', age: 21)
      expect(response.body).to eq('name=John, age=21')
    end

    it 'handles put requests' do
      put '/modify', name: 'zebra'
      expect(response.body).to eq('modified object zebra')
    end

    it 'handles patch requests' do
      patch '/update', name: 'lion'
      expect(response.body).to eq('updated object lion')
    end

    it 'handles delete requests' do
      delete '/object/34'
      expect(response.body).to eq('deleted 34')
    end

    describe 'head requests' do
      it 'handles head request headers' do
        head '/object/45'
        expect(response.headers['ETag']).to eq('object_45')
      end

      it 'does not return a body' do
        head '/object/45'
        expect(response.body).to be_nil
      end
    end
  end
end
