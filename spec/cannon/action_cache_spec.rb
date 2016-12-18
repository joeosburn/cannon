require 'spec_helper'

RSpec.describe Cannon::ActionCache do
  let(:cache) { {} }
  let(:route_action) { double('RouteAction', action: :action) }
  let(:action_cache) { described_class.new(route_action, cache: cache) }

  describe '#cached?' do
    context 'a cache entry exists' do
      before(:each) { cache['action_cache_action'] = :action }

      it 'returns true' do
        expect(action_cache.cached?).to be(true)
      end
    end

    context 'a cache entry does not exist' do
      it 'returns false' do
        expect(action_cache.cached?).to be(false)
      end
    end
  end
end
