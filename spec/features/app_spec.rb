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

RSpec.describe 'Cannon app' do
  before(:all) do
    cannon_app do |app|
      app.get('/hi', action: 'hi')
      app.get('/how', actions: ['hi', 'how', 'are_you'])
      app.get('/view', action: 'test_view')
      app.get('/bad', action: 'raise_500')
      app.get('/inline') do |request, response|
        response.send('inline action')
      end

      app.view_path = '../fixtures/views'
      app.public_path = '../fixtures/public'
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

    it 'handles inline actions' do
      get '/inline'
      expect(response.code).to eq('200')
      expect(response.body).to eq('inline action')
    end

    it 'renders a view' do
      get '/view'
      expect(response.body).to eq('Test view content')
      expect(response['Content-Type']).to eq('text/html')
    end

    it 'serves files' do
      get '/background.jpg'
      expect(response.body.size).to_not eq('')
      expect(response.code).to eq('200')
      expect(response['Content-Type']).to eq('image/jpeg')
      expect(response['Content-Length']).to eq('55697')
    end

    it 'returns 404 for not found routes' do
      get '/badroute'
      expect(response.code).to eq('404')
    end

    it 'returns 500 for errors' do
      get '/bad'
      expect(response.code).to eq('500')
    end
  end
end
