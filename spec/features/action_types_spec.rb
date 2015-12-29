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

def first(request, response, next_proc)
  EM.defer(
    -> { sleep 0.1 },
    ->(result) do
      response.send('first')
      next_proc.call
    end
  )
end

def second(request, response)
  response.send(' second')
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

  def first(request, response, next_proc)
    EM.defer(
      -> { sleep 0.1 },
      ->(result) do
        response.send('first')
        next_proc.call
      end
    )
  end

  def second(request, response)
    response.send(' second')
  end
end

RSpec.describe 'Cannon app', :cannon_app do
  before(:all) do
    cannon_app.get('/1-2-simple', actions: ['first', 'second'])
    cannon_app.get('/hi', action: 'hi')
    cannon_app.get('/how', actions: ['hi', 'how', 'are_you'])

    cannon_app.get('/hello', action: 'World#hello')
    cannon_app.get('/count', action: 'World#count')
    cannon_app.get('/1-2-controller', actions: ['World#first', 'World#second'])

    cannon_app.get('/inline') do |request, response|
      response.send('inline action')
    end

    cannon_app.get('/inline_chained') do |request, response|
      response.send('first')
    end.handle do |request, response|
      response.send(' second')
    end.handle do |request, response|
      response.send(' third')
    end

    cannon_app.get('/1-2-inline') do |request, response, next_proc|
      EM.defer(
        -> { sleep 0.1 },
        ->(result) do
          response.send('first')
          next_proc.call
        end
      )
    end.handle do |request, response|
      response.send(' second')
    end


    cannon_app.listen(async: true)
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

    it 'handles an actions chain' do
      get '/inline_chained'
      expect(response.body).to eq('first second third')
    end

    it 'handles next_proc calls for deferred processing' do
      get '/1-2-inline'
      expect(response.body).to eq('first second')
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