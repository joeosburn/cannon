require 'spec_helper'

RSpec.describe 'Files', :cannon_app do
  it 'serves files' do
    get '/background.jpg'
    expect(response.body.size).to_not eq('')
    expect(response.code).to be(200)
    expect(response['Content-Type']).to eq('image/jpeg')
    expect(response['Content-Length']).to eq('55697')
  end
end
