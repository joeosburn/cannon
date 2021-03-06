require 'spec_helper'

RSpec.describe 'Configuration' do
  describe 'view_path' do
    it 'can be relative', :cannon_app do
      cannon_app.config[:view_path] = '../fixtures/views'
      cannon_app.get('/') do |_request, response|
        response.view('test.html')
      end
      get '/'
      expect(response.body).to eq('Test view content')
    end

    it 'can be absolute', :cannon_app do
      cannon_app.config[:view_path] = cannon_app.runtime.root.to_s + '/../fixtures/views'
      cannon_app.get('/') do |_request, response|
        response.view('test.html')
      end
      get '/'
      expect(response.body).to eq('Test view content')
    end
  end

  describe 'public_path' do
    it 'can be relative', :cannon_app do
      cannon_app.config[:public_path] = '../fixtures/public'
      get '/background.jpg'
      expect(response.code).to be(200)
    end

    it 'can be absolute', :cannon_app do
      cannon_app.config[:public_path] = cannon_app.runtime.root.to_s + '/../fixtures/public'
      get '/background.jpg'
      expect(response.code).to be(200)
    end
  end
end
