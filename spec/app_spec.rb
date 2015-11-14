require 'spec_helper'

RSpec.describe Cannon::App do
  let!(:app) do
    app = Cannon::App.new(binding)
    app.config.log_level = :error
    app
  end

  context 'app is listening asynchronously' do
    before(:each) { app.listen(async: true, port: 3030) }

    it 'raises an error if trying to listen again before stopping' do
      expect(-> { app.listen }).to raise_error(Cannon::AlreadyListening)
    end

    context 'app has been stopped' do
      before(:each) { app.stop }

      it 'does not raise an error' do
        expect(-> { app.listen }).to_not raise_error
      end
    end
  end
end
