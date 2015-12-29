require 'spec_helper'

RSpec.describe 'Cookies', :cannon_app do
  before(:all) do
    cannon_app.get('/basic') do |request, response|
      response.send("cookie = #{request.cookies[:simple]}")
      request.cookies[:simple] = 'value'
    end

    cannon_app.get('/cookies') do |request, response|
      response.send("username = #{request.cookies[:username]}, password = #{request.cookies[:password]}, remember_me = #{request.cookies[:remember_me]}")
      request.cookies[:remember_me] = 'true'
      request.cookies[:username] = {value: '"Luther;Martin"', expires: Time.new(2017, 10, 31, 10, 30, 05), httponly: true}
      request.cookies[:password] = 'by=faith'
    end

    cannon_app.get('/signed') do |request, response|
      response.send("secure value = #{request.signed_cookies[:secure_value]}")
      request.signed_cookies[:secure_value] = 'SECURE'
    end

    cannon_app.get('/update') do |request, response|
      request.cookies[:simple] = 'new value'
      request.cookies[:complex] = {value: 'more complex', httponly: true}
      request.signed_cookies[:signed] = {value: 'a signed value'}
      response.send("simple = #{request.cookies[:simple]}")
      response.send(" complex = #{request.cookies[:complex]}")
      response.send(" signed = #{request.signed_cookies[:signed]}")
    end

    cannon_app.listen(async: true)
  end

  it 'reads and writes cookies' do
    get '/basic'
    expect(response.body).to eq('cookie = ')

    get '/basic'
    expect(response.body).to eq('cookie = value')
  end

  it 'handles cookie options' do
    get '/cookies'
    expect(response.body).to eq('username = , password = , remember_me = ')

    expect(cookies[:username].httponly).to be true
    expect(cookies[:username].expires).to eq(Time.new(2017, 10, 31, 10, 30, 05))
    expect(cookies[:password].expires).to be nil

    get '/cookies'
    expect(response.body).to eq('username = "Luther;Martin", password = by=faith, remember_me = true')
  end

  it 'updates cookie values in place' do
    get '/basic'
    get '/update'

    expect(response.body).to eq('simple = new value complex = more complex signed = a signed value')
  end

  describe 'signed' do
    before(:each) do
      get '/signed'
      expect(response.body).to eq('secure value = ')
    end

    it 'will work if the cookie is not tampered' do
      get '/signed'
      expect(response.body).to eq('secure value = SECURE')
    end

    it 'will clear the cookie if the cookie is tampered' do
      cookies[:secure_value].value.gsub!('SECURE', 'SeCURE')
      get '/signed'
      expect(response.body).to eq('secure value = ')
    end
  end
end
