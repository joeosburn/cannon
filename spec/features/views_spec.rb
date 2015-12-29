require 'spec_helper'

RSpec.describe 'Views', :cannon_app do
  before(:all) do
    cannon_app.config.view_path = '../fixtures/views'

    cannon_app.get('/view') do |request, response|
      response.view('test.html')
    end

    cannon_app.get('/render') do |request, response|
      response.view('render_test.html', name: 'John Calvin')
    end

    cannon_app.listen(async: true)
  end

  describe 'rendering' do
    it 'handles plain text' do
      get '/view'
      expect(response.body).to eq('Test view content')
      expect(response.code).to be(200)
      expect(response['Content-Type']).to eq('text/html')
    end

    it 'handles mustache templates' do
      get '/render'
      expect(response.body).to eq('Hello John Calvin')
    end
  end
end