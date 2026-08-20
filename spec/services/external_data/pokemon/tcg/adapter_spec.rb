require 'rails_helper'

RSpec.describe ExternalData::Pokemon::Tcg::Adapter do
  subject(:adapter) { described_class.new(game:) }

  let(:game) { create(:game) }

  it_behaves_like 'an external data adapter'

  describe '#players' do
    let(:player) do
      ExternalData::Player.new(
        attributes: { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791' }
      )
    end

    context 'when a season covers the current date' do
      before do
        create(:season, game:, start_date: 1.month.ago.to_date, end_date: 1.month.from_now.to_date, label: '2026')
        allow(ExternalData::Pokemon::Tcg::LabsPlayers).to receive(:call).and_return([player])
      end

      it 'delegates to LabsPlayers with the current season label' do
        adapter.players

        expect(ExternalData::Pokemon::Tcg::LabsPlayers).to have_received(:call).with(season: '2026')
      end

      it 'returns the fetched players' do
        expect(adapter.players).to eq([player])
      end
    end

    context 'when a season is explicitly injected' do
      let(:past_season) do
        create(:season, game:, start_date: 2.years.ago.to_date, end_date: 1.year.ago.to_date, label: '2024')
      end

      before { allow(ExternalData::Pokemon::Tcg::LabsPlayers).to receive(:call).and_return([player]) }

      it 'fetches with the injected season instead of resolving the current one' do
        described_class.new(game:, season: past_season).players

        expect(ExternalData::Pokemon::Tcg::LabsPlayers).to have_received(:call).with(season: '2024')
      end
    end

    context 'when no season covers the current date' do
      it 'raises a semantic error instead of fetching with a nil season' do
        message = "ExternalData::Pokemon::Tcg::Adapter: no Season row covers #{Date.current} for game " \
                  "'#{game.id}' — seed a Season before running this job."

        expect { adapter.players }.to raise_error(RuntimeError, message)
      end
    end
  end

  describe '#upcoming_tournaments' do
    it 'delegates to Pokemon::Tcg::Tournaments' do
      allow(ExternalData::Pokemon::Tcg::Tournaments).to receive(:upcoming_tournaments).and_return(:tournaments)

      expect(adapter.upcoming_tournaments).to eq(:tournaments)
    end
  end
end
