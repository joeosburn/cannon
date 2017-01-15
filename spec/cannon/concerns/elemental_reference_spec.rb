require 'spec_helper'

RSpec.describe ElementalReference do
  let(:included_class) { Class.new { include ElementalReference } }

  before do
    included_class.class_eval do
      protected

      attr_accessor :one
    end
  end

  subject { included_class.new }

  describe '#[]' do
    context 'a method with the name of the value exists' do
      before { allow(subject).to receive(:one).and_return(:one_value) }

      it 'returns the value of the method' do
        expect(subject).to receive(:one)
        expect(subject[:one]).to eq(:one_value)
      end
    end

    context 'a method with the name of the value does not exists' do
      it 'raises an UnknownKey error' do
        expect(-> { subject[:two] }).to raise_error(ElementalReference::UnknownKey)
      end
    end
  end

  describe '#[]=' do
    context 'a setter method with the name of the value exists' do
      before { allow(subject).to receive(:one=) }

      it 'gets called with the given value' do
        expect(subject).to receive(:one=).with(:new_value)
        subject[:one] = :new_value
      end
    end

    context 'a setter method with the name of the value does not exists' do
      it 'raises an UnknownKey error' do
        expect(-> { subject[:two] = :new_value }).to raise_error(ElementalReference::UnknownKey)
      end
    end
  end
end
