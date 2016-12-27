require 'spec_helper'

Object.send(:define_method, :called) { |arg| }

def simple(request, response)
  Object.called('simple')
  response.send('simple response')
end

def respond_201(request, response)
  Object.called('send 201')
  response.send('201 created', status: :created)
end

def headers(request, response)
  Object.called('headers')
  response.header('A-Website', 'http://www.google.com')
  response.header('B-Header', 'http://www.drudgereport.com')
  response.send('Headers')
end

def cookies(request, response)
  Object.called('cookies')
  request.cookies['username'] = {value: '"Luther;Martin"', expires: Time.new(2017, 10, 31, 10, 30, 05), httponly: true}
  request.cookies['password'] = {value: 'by=faith', max_age: 400}
  response.send('Cookies')
end

class World
  def initialize(app)
  end

  def home(request, response)
    Object.called('home')
    response.send('controller response')
  end
end

RSpec.describe 'Action caching', :cannon_app do
  before do
    cannon_app.get('/simple', action: 'simple')
    cannon_app.get('/home', action: 'World#home')
    cannon_app.get('/inline') do |request, response|
      Object.called('inline')
      response.send('inline response')
    end

    cannon_app.all('/any', action: 'simple')

    cannon_app.get('/nocache', action: 'simple', cache: false)

    cannon_app.get('/create', action: 'respond_201')
    cannon_app.get('/headers', action: 'headers')
    cannon_app.get('/cookies', action: 'cookies')
  end

  describe 'GET requests' do
    it 'caches controller and simple actions' do
      expect(Object).to receive(:called).with('simple').exactly(1).times
      expect(Object).to receive(:called).with('home').exactly(1).times

      get('/simple')
      expect(response.body).to eq('simple response')
      expect(response.code).to eq(200)
      get('/simple')
      expect(response.body).to eq('simple response')
      expect(response.code).to eq(200)

      get('/home')
      expect(response.body).to eq('controller response')
      expect(response.code).to eq(200)
      get('/home')
      expect(response.body).to eq('controller response')
      expect(response.code).to eq(200)
    end

    it 'does not cache inline actions' do
      expect(Object).to receive(:called).with('inline').exactly(2).times

      get('/inline')
      expect(response.body).to eq('inline response')
      expect(response.code).to eq(200)
      get('/inline')
      expect(response.body).to eq('inline response')
      expect(response.code).to eq(200)
    end

    it 'can have caching disabled' do
      expect(Object).to receive(:called).with('simple').exactly(2).times

      get('/nocache')
      expect(response.body).to eq('simple response')
      expect(response.code).to eq(200)
      get('/nocache')
      expect(response.body).to eq('simple response')
      expect(response.code).to eq(200)
    end

    it 'caches response codes' do
      expect(Object).to receive(:called).with('send 201').exactly(1).times

      get('/create')
      expect(response.body).to eq('201 created')
      expect(response.code).to eq(201)
      get('/create')
      expect(response.body).to eq('201 created')
      expect(response.code).to eq(201)
    end

    it 'caches custom headers' do
      expect(Object).to receive(:called).with('headers').exactly(1).times

      get('/headers')
      expect(response.body).to eq('Headers')
      expect(response.headers['a-website']).to eq('http://www.google.com')
      expect(response.headers['b-header']).to eq('http://www.drudgereport.com')
      get('/headers')
      expect(response.body).to eq('Headers')
      expect(response.headers['a-website']).to eq('http://www.google.com')
      expect(response.headers['b-header']).to eq('http://www.drudgereport.com')
    end

    it 'caches cookies' do
      expect(Object).to receive(:called).with('cookies').exactly(1).times

      get('/cookies')
      expect(response.body).to eq('Cookies')
      expect(cookies['username'].httponly).to be true
      expect(cookies['username'].expires).to eq(Time.new(2017, 10, 31, 10, 30, 05))
      expect(cookies['password'].max_age).to eq(400)
      jar.clear
      get('/cookies')
      expect(response.body).to eq('Cookies')
      expect(cookies['username'].httponly).to be true
      expect(cookies['username'].expires).to eq(Time.new(2017, 10, 31, 10, 30, 05))
      expect(cookies['password'].max_age).to eq(400)
    end
  end

  %w{PUT POST PATCH DELETE}.each do |request_type|
    describe "#{request_type} requests" do
      it 'does not cache actions' do
        expect(Object).to receive(:called).with('simple').exactly(2).times

        send(request_type.downcase.to_sym, '/any')
        expect(response.body).to eq('simple response')
        expect(response.code).to eq(200)
        send(request_type.downcase.to_sym, '/any')
        expect(response.body).to eq('simple response')
        expect(response.code).to eq(200)
      end
    end
  end
end
