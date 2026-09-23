require 'rails_helper'

RSpec.describe Demo::Games do
  describe '::ALL' do
    subject(:entries) { described_class::ALL }

    it 'lists at least one entry' do
      expect(entries).not_to be_empty
    end

    it 'gives every entry a unique id' do
      expect(entries.map(&:id).uniq.length).to eq(entries.length)
    end

    it 'gives every entry a Shape, a history curve, and at least one past tournament' do
      entries.each do |entry|
        expect(entry.shape).to be_a(Demo::Shape)
        expect(entry.history_curve).to respond_to(:call)
        expect(entry.past_tournament_count).to be_positive
      end
    end
  end
end
