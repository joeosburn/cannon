require 'spec_helper'

RSpec.describe 'Session', :cannon_app do
  before(:all) do
    cannon_app.get('/member') do |request, response|
      if request.session['logged_in'] != 'true'
        response.temporary_redirect('/login')
      else
        response.send("hello #{request.session['username']}")
      end
    end

    cannon_app.post('/login') do |request, response|
      if request.params[:username] && request.params[:password]
        request.session['username'] = request.params[:username]
        request.session['logged_in'] = 'true'
        response.temporary_redirect('/member')
      else
        response.send('Invalid Login')
      end
    end

    cannon_app.get('/logout') do |request, response|
      request.session.delete('username')
      request.session['logged_in'] = 'false'
      response.send('Logged out')
    end

    cannon_app.get('/session-info') do |request, response|
      response.send("logged_in = '#{request.session['logged_in']}',")
      response.send(" username nil? = #{request.session['username'].nil?}")
    end

    cannon_app.listen(async: true)
  end

  it 'maintains session between requests' do
    get '/member'
    expect(response.headers).to redirect_to('/login')

    post '/login', username: 'joe', password: 'osburn'
    expect(response.headers).to redirect_to('/member')

    get '/member'
    expect(response.body).to eq('hello joe')
  end

  it 'allows session variables to be deleted' do
    post '/login', username: 'joe', password: 'pass'
    get '/logout'
    get '/session-info'
    expect(response.body).to eq("logged_in = 'false', username nil? = true")
  end
end
