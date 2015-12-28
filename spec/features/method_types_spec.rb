require 'spec_helper'

RSpec.describe 'Method types', :cannon_app do
  before(:all) do
    cannon_app.get('/hi') do |request, response|
      response.send('hi')
    end

    cannon_app.get('/value') do |request, response|
      response.send("key = #{request.params[:key]}, place = #{request.params[:place]}")
    end

    cannon_app.post('/hi') do |request, response|
      response.send('created!', status: :created)
    end

    cannon_app.post('/submit') do |request, response|
      response.send("name=#{request.params[:name]}, age=#{request.params[:age]}")
    end

    cannon_app.patch('/update') do |request, response|
      response.send("updated object #{request.params[:name]}")
    end

    cannon_app.put('/modify') do |request, response|
      response.send("modified object #{request.params[:name]}")
    end

    cannon_app.delete('/object/:id') do |request, response|
      response.send("deleted #{request.params[:id]}")
    end

    cannon_app.head('/object/:id') do |request, response|
      response.header('ETag', "object_#{request.params[:id]}")
      response.send('head body should be ignored')
    end

    cannon_app.all('/any') do |request, response|
      response.send("request method = #{request.method}")
    end

    cannon_app.listen(async: true)
  end

  it 'handles get requests' do
    get '/hi'
    expect(response.code).to be(200)
    expect(response.body).to eq('hi')
  end

  it 'handles query params' do
    get '/value', key: 'a value', place: '12 ave st'
    expect(response.body).to eq('key = a value, place = 12 ave st')
  end

  it 'handles post requests' do
    post '/hi'
    expect(response.body).to eq('created!')
    expect(response.code).to eq(201)
  end

  it 'handles post params' do
    post('/submit', name: 'John', age: 21)
    expect(response.body).to eq('name=John, age=21')
  end

  it 'handles put requests' do
    put '/modify', name: 'zebra'
    expect(response.body).to eq('modified object zebra')
  end

  it 'handles patch requests' do
    patch '/update', name: 'lion'
    expect(response.body).to eq('updated object lion')
  end

  it 'handles delete requests' do
    delete '/object/34'
    expect(response.body).to eq('deleted 34')
  end

  describe 'head requests' do
    it 'handles head request headers' do
      head '/object/45'
      expect(response.headers['etag']).to eq('object_45')
    end

    it 'does not return a body' do
      head '/object/45'
      expect(response.body).to be_nil
    end
  end

  it 'can be configured to handle all methods for routes' do
    get '/any'
    expect(response.body).to eq('request method = GET')

    post '/any'
    expect(response.body).to eq('request method = POST')

    put '/any'
    expect(response.body).to eq('request method = PUT')
  end
end
