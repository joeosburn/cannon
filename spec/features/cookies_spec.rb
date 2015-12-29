require 'spec_helper'

RSpec.describe 'Cookies', :cannon_app do
  before(:all) do
    cannon_app.get('/basic') do |request, response|
      response.cookie(:simple, value: 'value')
      response.send("cookie = #{request.cookies[:simple]}")
    end

    cannon_app.get('/cookies') do |request, response|
      response.cookie(:remember_me, value: 'true')
      response.cookie(:username, value: '"Luther;Martin"', expires: Time.new(2017, 10, 31, 10, 30, 05), httponly: true)
      response.cookie(:password, value: 'by=faith')
      response.send("username = #{request.cookies[:username]}, password = #{request.cookies[:password]}, remember_me = #{request.cookies[:remember_me]}")
    end

    cannon_app.get('/signed') do |request, response|
      response.cookie(:secure_value, value: 'SECURE', signed: true)
      response.send("secure value = #{request.cookies.signed[:secure_value]}")
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