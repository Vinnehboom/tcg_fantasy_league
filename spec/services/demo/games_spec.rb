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

    it 'gives every entry a Shape and a history curve' do
      entries.each do |entry|
        expect(entry.shape).to be_a(ExternalData::Synthetic::Shape)
        expect(entry.history_curve).to respond_to(:call)
      end
    end

    it 'includes PTCG, shaped as an accumulating ladder' do
      ptcg = entries.find { |entry| entry.id == 'PTCG' }

      expect(ptcg.shape.score_curve).to eq(ExternalData::Synthetic::ScoreCurves::LADDER)
      expect(ptcg.history_curve).to eq(Demo::HistoryCurves::ACCUMULATING)
    end

    it 'includes RIFT, shaped as a wandering ELO band' do
      rift = entries.find { |entry| entry.id == 'RIFT' }

      expect(rift.shape.score_curve).to eq(ExternalData::Synthetic::ScoreCurves::ELO_BAND)
      expect(rift.history_curve).to eq(Demo::HistoryCurves::WANDERING)
    end
  end
end
