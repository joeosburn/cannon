require 'spec_helper'

RSpec.describe Cannon::Response do
  let(:delegated_response) { double(Object) }
  let(:app) { Cannon::App.new(binding) }
  let(:response) { described_class.new(delegated_response, app: app) }

  describe '#flush' do
    before(:each) do
      allow(delegated_response).to receive(:send_headers)
      allow(delegated_response).to receive(:send_response)
    end

    it 'sets flushed to true' do
      expect(response).to_not be_flushed
      response.flush
      expect(response).to be_flushed
    end

    it 'sends delegated_response headers' do
      expect(delegated_response).to receive(:send_headers)
      response.flush
    end

    it 'sends delegated_response response' do
      expect(delegated_response).to receive(:send_response)
      response.flush
    end
  end
end
