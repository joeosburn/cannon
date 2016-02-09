require 'spec_helper'

Object.send(:define_method, :called) {|arg|}

def simple(request, response)
  Object.called('simple')
  response.send('simple response')
end

class World
  def home(request, response)
    Object.called('home')
    response.send('controller response')
  end
end

RSpec.describe 'Action caching', :cannon_app do
  before(:each) do
    cannon_app.get('/simple', action: 'simple')
    cannon_app.get('/home', action: 'World#home')
    cannon_app.get('/inline') do |request, response|
      Object.called('inline')
      response.send('inline response')
    end

    cannon_app.all('/any', action: 'simple')

    cannon_app.listen(async: true)
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
