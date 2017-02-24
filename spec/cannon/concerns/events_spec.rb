require 'spec_helper'

RSpec.describe Events do
  subject { Object.new }
  let(:dummy) { double }

  describe 'emitting events' do
    before{ allow(dummy).to receive(:call) }

    it 'calls the block on emit' do
      subject.on(:event) { dummy.call }
      expect(dummy).to receive(:call)
      subject.emit(:event)
    end

    it 'passes arguments to the block' do
      subject.on(:bad_event) { dummy.call(:x, 1) }
      subject.on(:good_event) { |a, b| dummy.call(a, b) }
      expect(dummy).to receive(:call).with(3, :y)
      subject.emit(:good_event, 3, :y)
    end

    it 'handles multiple event listeners' do
      subject.on(:event) { dummy.call(1) }
      subject.on(:event) { dummy.call(2) }
      expect(dummy).to receive(:call).with(1).exactly(1).times.ordered
      expect(dummy).to receive(:call).with(2).exactly(1).times.ordered
      subject.emit(:event)
    end
  end
end
