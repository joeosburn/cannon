require 'spec_helper'

RSpec.describe 'Cannon environment', :cannon_app do
  context 'no environment specified' do
    before(:each) { ENV['CANNON_ENV'] = nil }

    it 'sets the environment to development' do
      expect(Cannon.env).to eq('development')
    end
  end

  context 'environment specified' do
    before(:each) { ENV['CANNON_ENV'] = 'strange' }

    it 'sets the environment to the environment specified' do
      expect(Cannon.env).to eq('strange')
    end
  end

  describe 'environment helper methods' do
    before(:each) do
      ENV['CANNON_ENV'] = 'carrots'

      Cannon.environment(:potatoes) {}
      Cannon.environment(:celeries) {}
      Cannon.environment(:onions, :lettuce, :pickles)
    end

    it 'creates a helper method for current environment' do
      expect(Cannon.env.carrots?).to be(true)
    end

    it 'creates helper methods for single configured environments' do
      expect(Cannon.env.potatoes?).to be(false)
      expect(Cannon.env.celeries?).to be(false)
    end

    it 'creates helper methods for multi configured environments' do
      expect(Cannon.env.onions?).to be(false)
      expect(Cannon.env.lettuce?).to be(false)
      expect(Cannon.env.pickles?).to be(false)
    end
  end

  describe 'environment specific config blocks' do
    before(:each) do
      ENV['CANNON_ENV'] = 'carrots'

      Cannon.environment(:potatoes) do
        cannon_app.config.view_path = 'potatoes_view_path'
        cannon_app.runtime.config.log_level = :debug
      end
      Cannon.environment(:carrots) do
        cannon_app.config.view_path = 'carrots_view_path'
        cannon_app.runtime.config.log_level = :warn
      end
      Cannon.environment(:pickles) do
        cannon_app.config.public_path = 'pickles_view_path'
        cannon_app.runtime.config.log_level = :error
      end
      Cannon.environment(:onions, :carrots) do
        cannon_app.config.public_path = 'shared_view_path'
      end
    end

    it 'runs the configuration for the given environment' do
      expect(cannon_app.config.view_path).to eq('carrots_view_path')
      expect(cannon_app.config.public_path).to eq('shared_view_path')
      expect(cannon_app.runtime.config.log_level).to eq(:warn)
    end
  end
end
