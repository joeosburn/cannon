require 'spec_helper'

RSpec.describe Cannon::Runtime do
  let(:runtime) { Cannon::Runtime.new(File.dirname(__FILE__), :ip, :port) }

  describe '#load_env' do
    it 'loads a yaml file into ENV' do
      expect(ENV['APP_CODE']).to be_nil
      expect(ENV['SAMPLE']).to be_nil
      runtime.load_env(yaml_filename: '../fixtures/config/application.yml')
      expect(ENV['APP_CODE']).to eq('abc')
      expect(ENV['SAMPLE']).to eq('123')
    end
  end
end
