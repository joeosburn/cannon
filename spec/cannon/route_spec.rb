require 'spec_helper'

RSpec.describe Cannon::Route do
  let(:app) { Cannon::App.new(binding) }

  describe '#matches?' do
    context 'the methods do not match' do
      context 'the route method is ALL' do
        let(:route) { described_class.new('/some/path', [], app: app) }

        before { route.method = 'ALL' }

        context 'the paths match' do
          let(:request) { double(Cannon::Request, path: '/some/path', method: 'GET') }

          it 'returns true' do
            expect(route.matches?(request)).to be(true)
          end
        end

        context 'the paths do not match' do
          let(:request) { double(Cannon::Request, path: '/other/path', method: 'GET') }

          it 'returns false' do
            expect(route.matches?(request)).to be(false)
          end
        end
      end

      context 'the route method is not ALL' do
        let(:route) { described_class.new('/some/path', [], app: app) }
        let(:request) { double(Cannon::Request, path: '/some/path', method: 'GET') }

        before { route.method = 'POST' }

        it 'returns false' do
          expect(route.matches?(request)).to be(false)
        end
      end
    end

    context 'the methods match' do
      let(:route) { described_class.new('/some/path', [], app: app) }

      before { route.method = 'GET' }

      context 'the paths match' do
        let(:request) { double(Cannon::Request, path: '/some/path', method: 'GET') }

        it 'returns true' do
          expect(route.matches?(request)).to be(true)
        end
      end

      context 'the paths do not match' do
        let(:request) { double(Cannon::Request, path: '/other/path', method: 'GET') }

        it 'returns false' do
          expect(route.matches?(request)).to be(false)
        end
      end
    end

    describe 'path matching' do
      describe 'a regular path' do
        let(:route) { described_class.new('/location/a-city', [], app: app) }
        let(:request1) { double(Cannon::Request, path: '/location/a-city', method: 'GET') }
        let(:request2) { double(Cannon::Request, path: '/location/a-city/town', method: 'GET') }

        before { route.method = 'GET' }

        it 'matches' do
          expect(route.matches?(request1)).to be(true)
          expect(route.matches?(request2)).to be(false)
        end
      end

      describe 'a path with url params' do
        let(:route) { described_class.new(':type/catalog/:id', [], app: app) }
        let(:request1) { double(Cannon::Request, path: '/chairs/catalog/big', method: 'GET') }
        let(:request2) { double(Cannon::Request, path: '/chairs/catalog/', method: 'GET') }
        let(:request3) { double(Cannon::Request, path: '/locations/catalog/5', method: 'GET') }
        let(:request4) { double(Cannon::Request, path: '//places/catalog/4', method: 'GET') }

        before { route.method = 'GET' }

        it 'matches' do
          expect(route.matches?(request1)).to be(true)
          expect(route.matches?(request2)).to be(false)
          expect(route.matches?(request3)).to be(true)
          expect(route.matches?(request4)).to be(false)
        end
      end

      describe 'a path with irregular url params' do
        let(:route) { described_class.new(':category-thing/:id.html', [], app: app) }
        let(:request1) { double(Cannon::Request, path: '/chairs-thing/5.html', method: 'GET') }
        let(:request2) { double(Cannon::Request, path: '/chairs-blah/6', method: 'GET') }
        let(:request3) { double(Cannon::Request, path: '/other-thing/city.html', method: 'GET') }
        let(:request4) { double(Cannon::Request, path: '//-thing/.html', method: 'GET') }

        before { route.method = 'GET' }

        it 'matches' do
          expect(route.matches?(request1)).to be(true)
          expect(route.matches?(request2)).to be(false)
          expect(route.matches?(request3)).to be(true)
          expect(route.matches?(request4)).to be(false)
        end
      end
    end
  end
end
