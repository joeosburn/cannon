require 'spec_helper'

RSpec.describe 'Cookies', :cannon_app do
  before(:all) do
    cannon_app.get('/cookies') do |request, response|
      response.cookie(:remember_me, value: 'true')
      response.cookie(:username, value: '"Luther;Martin"', expires: Time.new(2017, 10, 31, 10, 30, 05), httponly: true)
      response.cookie(:password, value: 'by=faith')
      response.send("username = #{request.cookies[:username]}, password = #{request.cookies[:password]}, remember_me = #{request.cookies[:remember_me]}")
    end

    cannon_app.listen(async: true)
  end

  it 'handles cookies' do
    get '/cookies'
    expect(response.body).to eq('username = , password = , remember_me = ')

    expect(cookies[:username][:httponly]).to be true
    expect(cookies[:username][:expires]).to eq(Time.new(2017, 10, 31, 10, 30, 05))
    expect(cookies[:password][:expires]).to be nil

    get '/cookies'
    expect(response.body).to eq('username = "Luther;Martin", password = by=faith, remember_me = true')
  end
end
