require 'rails_helper'

module Tournaments

  RSpec.describe SetResultsSourceId do
    let(:tournament) { create(:tournament, results_source_id: nil) }

    context 'with a present results_source_id' do
      it 'sets the tournament\'s results_source_id' do
        described_class.call(tournament:, results_source_id: '0070')

        expect(tournament.reload.results_source_id).to eq('0070')
      end

      it 'returns true' do
        result = described_class.call(tournament:, results_source_id: '0070')

        expect(result).to be(true)
      end
    end

    context 'with a blank results_source_id' do
      it 'does not change the tournament' do
        described_class.call(tournament:, results_source_id: '')

        expect(tournament.reload.results_source_id).to be_nil
      end

      it 'returns false' do
        result = described_class.call(tournament:, results_source_id: '')

        expect(result).to be(false)
      end
    end

    context 'with a results_source_id already used by another tournament' do
      before { create(:tournament, results_source_id: '0070') }

      it 'does not change the tournament' do
        described_class.call(tournament:, results_source_id: '0070')

        expect(tournament.reload.results_source_id).to be_nil
      end

      it 'returns false' do
        result = described_class.call(tournament:, results_source_id: '0070')

        expect(result).to be(false)
      end
    end
  end

end
