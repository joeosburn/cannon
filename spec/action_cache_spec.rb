require 'spec_helper'

RSpec.describe Cannon::ActionCache do
  let(:cache) { {} }
  let(:action_cache) { Cannon::ActionCache.new(cache: cache) }

  describe '#cached?' do
    context 'a cache entry exists' do
      before(:each) { cache['action_cache_action'] = :action }

      it 'returns true' do
        expect(action_cache.cached?('action')).to be(true)
      end
    end

    context 'a cache entry does not exist' do
      it 'returns false' do
        expect(action_cache.cached?('action')).to be(false)
      end
    end
  end

  describe '#clear' do
    before(:each) do
      cache['action_cache_one'] = :one
      cache['action_cache_Controller#two'] = :two
      cache['something_else'] = :other
      cache['action_cachetest'] = :test
    end

    it 'deletes all action caches' do
      action_cache.clear
      expect(cache['action_cache_one']).to be nil
      expect(cache['action_cache_Controller#two']).to be nil
    end

    it 'does not delete other cache entries' do
      action_cache.clear
      expect(cache['something_else']).to_not be nil
      expect(cache['action_cachetest']).to_not be nil
    end
   end
end
