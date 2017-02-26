require 'spec_helper'

RSpec.describe Cannon::Response do
  let(:delegated_response) { double('Delegated Response', headers: {}) }
  let(:response) { described_class.new(delegated_response) }

  describe '#flush' do
    before do
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

    context 'Content-Type set' do
      before { response.headers['Content-Type'] = 'text/html' }

      it 'does not alter the Content-Type' do
        response.flush
        expect(response.headers['Content-Type']).to eq('text/html')
      end
    end

    context 'Content-Type not set' do
      it 'sets the default content type' do
        response.flush
        expect(response.headers['Content-Type']).to eq('text/plain')
      end
    end
  end
end
