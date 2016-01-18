require 'spec_helper'

RSpec.describe 'Flash', :cannon_app do
  before(:each) do
    cannon_app.get('/assign') do |request, response|
      request.flash['notice'] = 'assigned'
      response.send('assigned')
    end

    cannon_app.get('/notice') do |request, response|
      response.send("notice = #{request.flash['notice']}")
    end

    cannon_app.listen(async: true)
  end

  it 'saves the flash variables for a single request' do
    get '/assign'
    get '/notice'
    expect(response.body).to eq('notice = assigned')

    get '/notice'
    expect(response.body).to eq('notice = ')
  end
end
