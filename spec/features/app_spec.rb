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

RSpec.describe 'Cannon app' do
  before(:all) do
    cannon_app do |app|
      app.get('/hi', action: 'hi')
      app.get('/how', actions: ['hi', 'how', 'are_you'])
    end
  end

  describe 'basic get request' do
    it 'handles a simple action' do
      get '/hi'
      expect(response.code).to eq('200')
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
      expect(response.code).to eq('200')
      expect(response.body).to eq('hi how are you?')
    end
  end
end
