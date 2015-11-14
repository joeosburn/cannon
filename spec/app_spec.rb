require 'spec_helper'

RSpec.describe Cannon::App do
  context 'app is listening asynchronously' do
    before(:each) { cannon_app.listen(port: 3030, async: true) }
    after(:each) { cannon_app.stop }

    it 'raises an error if trying to listen again before stopping' do
      expect(-> { cannon_app.listen }).to raise_error(Cannon::AlreadyListening)
    end

    context 'app has been stopped' do
      before(:each) { cannon_app.stop }

      it 'does not raise an error' do
        expect(-> { cannon_app.listen(async: true) }).to_not raise_error
      end
    end
  end
end
