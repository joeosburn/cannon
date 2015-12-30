require 'spec_helper'

RSpec.describe 'Session', :cannon_app do
  before(:all) do
    cannon_app.get('/member') do |request, response|
      if request.session['username'].nil?
        response.temporary_redirect('/login')
      else
        response.send("hello #{request.session['username']}")
      end
    end

    cannon_app.post('/login') do |request, response|
      if request.params[:username] && request.params[:password]
        request.session['username'] = request.params[:username]
        response.temporary_redirect('/member')
      else
        response.send('Invalid Login')
      end
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
end
