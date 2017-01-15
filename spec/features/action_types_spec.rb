require 'spec_helper'

def hi(_request, response)
  response.send('hi')
end

def how(_request, response)
  response.send(' how ')
end

def are_you(_request, response)
  response.send('are you?')
end

def first(_request, response, next_proc)
  EM.defer(
    lambda do
      response.send('first')
      next_proc.call
    end
  )
end

def second(_request, response)
  response.send(' second')
end

class World
  def initialize(_app)
    @count = 0
  end

  def hello(_request, response)
    response.send('Hello World!')
  end

  def count(_request, response)
    response.send("count = #{@count}")
    @count += 1
  end

  def first(_request, response, next_proc)
    EM.defer(
      lambda do
        response.send('first')
        next_proc.call
      end
    )
  end

  def second(_request, response)
    response.send(' second')
  end
end

RSpec.describe 'Action types', :cannon_app do
  before do
    cannon_app.get('/1-2-simple', actions: %w(first second))
    cannon_app.get('/hi', action: 'hi')
    cannon_app.get('/how', actions: %w(hi how are_you))

    cannon_app.get('/hello', action: 'World#hello')
    cannon_app.get('/count', action: 'World#count', cache: false)
    cannon_app.get('/1-2-controller', actions: ['World#first', 'World#second'])

    cannon_app.get('/inline') do |_request, response|
      response.send('inline action')
    end
  end

  describe 'simple method' do
    it 'handles single actions' do
      get '/hi'
      expect(response.code).to be(200)
      expect(response.body).to eq('hi')
    end

    it 'handles an actions chain' do
      get '/how'
      expect(response.code).to be(200)
      expect(response.body).to eq('hi how are you?')
    end

    it 'handles next_proc calls for deferred processing' do
      get '/1-2-simple'
      expect(response.body).to eq('first second')
    end
  end

  describe 'inline' do
    it 'handles single actions' do
      get '/inline'
      expect(response.code).to be(200)
      expect(response.body).to eq('inline action')
    end
  end

  describe 'controller based' do
    it 'handles simple actions' do
      get '/hello'
      expect(response.body).to eq('Hello World!')
      expect(response.code).to eq(200)
    end

    it 'handles next_proc calls for deferred processing' do
      get '/1-2-controller'
      expect(response.body).to eq('first second')
    end

    it 'keeps the instantiation of the controller' do
      get '/count'
      expect(response.body).to eq('count = 0')
      get '/count'
      expect(response.body).to eq('count = 1')
      get '/count'
      expect(response.body).to eq('count = 2')
    end
  end
end
