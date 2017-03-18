require 'spec_helper'

RSpec.describe Cannon::Response do
  let(:delegated_response) { double('Delegated Response', headers: {}) }
  let(:response) { described_class.new(delegated_response) }

  describe '#flush' do
    before do
      allow(delegated_response).to receive(:flush)
      allow(delegated_response).to receive(:flushed?) { false }
    end

    it 'flushes the delegated response' do
      expect(delegated_response).to receive(:flush)
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
