require 'spec_helper'

RSpec.describe 'Error handling', :cannon_app do
  before do
    cannon_app.get('/basic-error') do |request, response|
      response.fail_error
    end

    cannon_app.get('/render-error') do |request, response|
      response.view('render_error.html.mustache')
    end

    cannon_app.get('/defer-render-error') do |request, response, next_proc|
      EM.defer(
        -> do
          response.view('render_error.html.mustache')
        end
      )
    end

    cannon_app.get('/defer-error') do |request, response, next_proc|
      EM.defer(
        -> do
          response.defer_error
        end
      )
    end

    cannon_app.runtime.config[:log_level] = :fatal
  end

  describe 'an error in the action' do
    before { get '/basic-error' }

    it 'returns a 500' do
      expect(response.code).to eq(500)
    end

    it 'outputs the error' do
      expect(response.body).to include("undefined method `fail_error' for #<Cannon::Response")
    end
  end

  describe 'an error in a callback in an action' do
    before { get '/defer-error' }

    it 'returns a 500' do
      expect(response.code).to eq(500)
    end

    it 'outputs the error' do
      expect(response.body).to include("undefined method `defer_error' for #<Cannon::Response")
    end
  end

  describe 'an error in the template' do
    before { get '/render-error' }

    it 'returns a 500' do
      expect(response.code).to eq(500)
    end

    it 'outputs the error' do
      expect(response.body).to include('Internal Server Error: Unclosed tag')
      expect(response.body).to include('Test {{error}')
    end
  end

  describe 'an error in a template called from a callback in an action' do
    before { get '/defer-render-error' }

    it 'returns a 500' do
      expect(response.code).to eq(500)
    end

    it 'outputs the error' do
      expect(response.body).to include('Internal Server Error: Unclosed tag')
      expect(response.body).to include('Test {{error}')
    end
  end
end
