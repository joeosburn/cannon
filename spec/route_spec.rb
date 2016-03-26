require 'spec_helper'

RSpec.describe Cannon::Route do
  let(:app) { Cannon::App.new(binding) }

  describe '#matches?' do
    context 'the methods do not match' do
      context 'the route method is ALL' do
        let(:route) { described_class.new('/some/path', app: app, method: 'ALL', cache: false) }

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
        let(:route) { described_class.new('/some/path', app: app, method: 'POST', cache: false) }
        let(:request) { double(Cannon::Request, path: '/some/path', method: 'GET') }

        it 'returns false' do
          expect(route.matches?(request)).to be(false)
        end
      end
    end

    context 'the methods match' do
      let(:route) { described_class.new('/some/path', app: app, method: 'GET', cache: false) }

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
  end
end
