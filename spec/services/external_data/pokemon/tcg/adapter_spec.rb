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

  describe '#results' do
    context 'when the tournament has a labs_tournament_id' do
      let(:tournament) { create(:tournament, game:, labs_tournament_id: '0070') }

      it 'delegates to LabsStandings with the tournament\'s labs_tournament_id' do
        allow(ExternalData::Pokemon::Tcg::LabsStandings).to receive(:call).and_return([:results])

        adapter.results(tournament:)

        expect(ExternalData::Pokemon::Tcg::LabsStandings).to have_received(:call).with(tournament_id: '0070')
      end

      it 'returns the fetched results' do
        allow(ExternalData::Pokemon::Tcg::LabsStandings).to receive(:call).and_return([:results])

        expect(adapter.results(tournament:)).to eq([:results])
      end
    end

    context 'when the tournament has no labs_tournament_id' do
      let(:tournament) { create(:tournament, game:, labs_tournament_id: nil) }

      it 'raises a semantic error instead of fetching with a blank id' do
        message = "ExternalData::Pokemon::Tcg::Adapter: no labs_tournament_id set on tournament ##{tournament.id} " \
                  "('#{tournament.name}') — resolve it (e.g. via admin) before fetching Pokemon results."

        expect { adapter.results(tournament:) }.to raise_error(RuntimeError, message)
      end
    end
  end

  describe '#field_size' do
    context 'when the tournament has a labs_tournament_id' do
      let(:tournament) { create(:tournament, game:, labs_tournament_id: '0070') }

      context 'when LabsTournament returns an authoritative count' do
        before { allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call).and_return(3752) }

        it 'returns the authoritative count' do
          expect(adapter.field_size(tournament:)).to eq(3752)
        end

        it 'does not fall back to LabsStandings.entrant_count' do
          allow(ExternalData::Pokemon::Tcg::LabsStandings).to receive(:entrant_count)

          adapter.field_size(tournament:)

          expect(ExternalData::Pokemon::Tcg::LabsStandings).not_to have_received(:entrant_count)
        end
      end

      context 'when LabsTournament has no authoritative count available' do
        before do
          allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call).and_return(nil)
          allow(ExternalData::Pokemon::Tcg::LabsStandings).to receive(:entrant_count).and_return(3750)
        end

        it 'falls back to the raw standings entrant count' do
          expect(adapter.field_size(tournament:)).to eq(3750)
        end
      end

      it 'queries both services with the tournament\'s labs_tournament_id' do
        allow(ExternalData::Pokemon::Tcg::LabsTournament).to receive(:call).and_return(nil)
        allow(ExternalData::Pokemon::Tcg::LabsStandings).to receive(:entrant_count).and_return(3750)

        adapter.field_size(tournament:)

        expect(ExternalData::Pokemon::Tcg::LabsTournament).to have_received(:call).with(tournament_id: '0070')
        expect(ExternalData::Pokemon::Tcg::LabsStandings).to have_received(:entrant_count).with(tournament_id: '0070')
      end
    end

    context 'when the tournament has no labs_tournament_id' do
      let(:tournament) { create(:tournament, game:, labs_tournament_id: nil) }

      it 'raises a semantic error instead of fetching with a blank id' do
        message = "ExternalData::Pokemon::Tcg::Adapter: no labs_tournament_id set on tournament ##{tournament.id} " \
                  "('#{tournament.name}') — resolve it (e.g. via admin) before fetching Pokemon results."

        expect { adapter.field_size(tournament:) }.to raise_error(RuntimeError, message)
      end
    end
  end
end
