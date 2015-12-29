require 'spec_helper'

RSpec.describe 'Cannon environment', :cannon_app do
  context 'no environment specified' do
    before(:each) { ENV['CANNON_ENV'] = nil }

    it 'sets the environment to development' do
      expect(cannon_app.env).to eq('development')
    end
  end

  context 'environment specified' do
    before(:each) { ENV['CANNON_ENV'] = 'strange' }

    it 'sets the environment to the environment specified' do
      expect(cannon_app.env).to eq('strange')
    end
  end

  describe 'environment helper methods' do
    before(:each) do
      ENV['CANNON_ENV'] = 'carrots'

      cannon_app.configure(:potatoes) {}
      Cannon.configure(:celeries) {}
      cannon_app.configure(:onions, :lettuce, :pickles)
    end

    it 'creates a helper method for current environment' do
      expect(cannon_app.env.carrots?).to be(true)
    end

    it 'creates helper methods for single configured environments' do
      expect(cannon_app.env.potatoes?).to be(false)
      expect(cannon_app.env.celeries?).to be(false)
    end

    it 'creates helper methods for multi configured environments' do
      expect(cannon_app.env.onions?).to be(false)
      expect(cannon_app.env.lettuce?).to be(false)
      expect(cannon_app.env.pickles?).to be(false)
    end
  end

  describe 'environment specific config blocks' do
    before(:each) do
      ENV['CANNON_ENV'] = 'carrots'

      cannon_app.configure(:potatoes) do |config|
        config.view_path = 'potatoes_view_path'
      end
      cannon_app.configure(:carrots) do |config|
        config.view_path = 'carrots_view_path'
      end
      Cannon.configure(:pickles) do |config|
        config.public_path = 'pickles_view_path'
      end
      cannon_app.configure(:onions, :carrots) do |config|
        config.public_path = 'shared_view_path'
      end
    end

    it 'runs the configuration for the given environment' do
      expect(Cannon.config.view_path).to eq('carrots_view_path')
      expect(Cannon.config.public_path).to eq('shared_view_path')
    end
  end
end
