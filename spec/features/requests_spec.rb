require 'spec_helper'

RSpec.describe 'Requests', :cannon_app do
  before do
    cannon_app.get('/basic') do |request, response|
      response.send('hi how are you doing?')
    end

    cannon_app.get('/bad') do |response, request|
      bad_fail_code
    end

    cannon_app.get('/resource/:id') do |request, response|
      response.send("id = #{request.params[:id]}")
    end

    cannon_app.get('/:type/by-grouping/:grouping') do |request, response|
      response.send("type=#{request.params[:type]}, grouping=#{request.params[:grouping]}, sort=#{request.params[:sort]}")
    end

    cannon_app.get('/object/:id') do |request, response|
      response.send("view #{request.params[:id]}")
    end
  end

  it 'sets the Content-Type' do
    get '/basic'
    expect(response['Content-Type']).to eq('text/plain; charset=us-ascii')
  end

  it 'sets the Content-Length' do
    get '/basic'
    expect(response['Content-Length']).to eq('21')
  end

  it 'handles params in routes' do
    get '/resource/12'
    expect(response.body).to eq('id = 12')
    get '/messages/by-grouping/author', sort: 'name'
    expect(response.body).to eq('type=messages, grouping=author, sort=name')
  end

  it 'returns 404 for not found routes' do
    get '/badroute'
    expect(response.code).to be(404)
  end

  it 'returns 500 for errors' do
    old_log_level = cannon_app.runtime.config[:log_level]
    cannon_app.runtime.config[:log_level] = :fatal
    get '/bad'
    expect(response.code).to be(500)
    cannon_app.runtime.config[:log_level] = old_log_level
  end
end
