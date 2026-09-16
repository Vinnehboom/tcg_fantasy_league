require 'rails_helper'

RSpec.describe ExternalData::Interface do
  let(:game) { create(:game) }

  def fake_adapter(players: nil, upcoming_tournaments: nil, results: nil)
    adapter = Struct.new(:players, :upcoming_tournaments, keyword_init: true).new(players:, upcoming_tournaments:)
    adapter.define_singleton_method(:results) { |**| results }
    adapter
  end

  describe 'players' do
    let(:season) { create(:season, game:) }
    let(:players) do
      [
        { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791', season: },
        { name: 'Efrain Herman', country: 'MQ', external_id: '/players/6', external_points: '399', season: },
        { name: 'Guadalupe Ernser', country: 'MF', external_id: '/players/7', external_points: '460', season: },
        { name: 'Janyce Gusikowski V', country: 'DO', external_id: '/players/8', external_points: '163', season: }
      ].map { |attributes| ExternalData::Player.new(attributes:) }
    end

    describe '#players' do
      describe 'when an adapter is injected' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(players:)) }

        it 'retrieves all the players for the game' do
          expect(interface.players.map(&:instance_values)).to include(players.sample.instance_values)
        end

        it 'includes a relation to the related game for the players' do
          expect(interface.players.sample.game_id).to eq(game.id)
        end
      end

      describe 'when no adapter is injected' do
        let(:interface) { described_class.new(game:) }

        it 'raises an exception' do
          expect { interface.players }.to raise_error(ExternalData::Exception)
        end
      end
    end

    describe '#update_players' do
      describe 'when an adapter is injected' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(players:)) }

        describe 'when the player data exists' do
          let(:player) { players.sample }
          let!(:db_player) do
            create(:player, **player.instance_values.slice!('external_points', 'season'), game_id: game.id)
          end

          it 'updates the players information' do
            interface.update_players
            expect(Player.find_by(name: player.name).country).to eq(player.country)
          end

          it 'looks up the batch of existing players in one query, not once per player' do
            expect(count_queries(pattern: /FROM "players"/) { interface.update_players }).to eq(1)
          end

          describe 'when the external score has been updated' do
            let(:interface) { described_class.new(game:, adapter: fake_adapter(players: [player])) }

            it 'creates a new score' do
              expect { interface.update_players }.to change(ExternalScore, :count).by(1)
            end
          end

          describe 'when the external score has not changed' do
            let(:interface) { described_class.new(game:, adapter: fake_adapter(players: [player])) }

            it 'does not create a new score' do
              create(:external_score, player: db_player, score: player.external_points)
              expect { interface.update_players }.not_to change(ExternalScore, :count)
            end
          end
        end

        describe 'when the players data does not exist yet' do
          it 'saves the players information' do
            expect { interface.update_players }.to change(Player, :count).by(players.length)
          end

          it 'returns how many players were processed' do
            expect(interface.update_players).to eq(players.length)
          end

          it 'looks up the batch of players in one query, not once per player' do
            expect(count_queries(pattern: /FROM "players"/) { interface.update_players }).to eq(1)
          end

          it 'reads no score, because a player season it creates cannot hold one yet' do
            expect(count_queries(pattern: /FROM "external_scores"/) { interface.update_players }).to eq(0)
          end
        end

        describe 'when the adapter returns the same player twice' do
          let(:repeated) do
            [
              { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791', season: },
              { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791', season: }
            ].map { |attributes| ExternalData::Player.new(attributes:) }
          end
          let(:interface) { described_class.new(game:, adapter: fake_adapter(players: repeated)) }

          it 'creates one player row, not one per entry' do
            expect { interface.update_players }.to change(Player, :count).by(1)
          end

          it 'creates one player season row, not one per entry' do
            expect { interface.update_players }.to change(PlayerSeason, :count).by(1)
          end
        end

        describe 'when every player in the batch already exists' do
          before do
            players.each do |player|
              create(:player, :without_scores, **player.instance_values.slice!('external_points', 'season'),
                     game_id: game.id)
            end
          end

          it 'looks up the batch of existing players in one query, not once per player' do
            expect(count_queries(pattern: /FROM "players"/) { interface.update_players }).to eq(1)
          end

          it 'looks up the batch of player seasons in one query, not once per player' do
            expect(count_queries(pattern: /FROM "player_seasons"/) { interface.update_players }).to eq(1)
          end

          it 'reads the latest score of the batch in one query, not once per player' do
            expect(count_queries(pattern: /FROM "external_scores"/) { interface.update_players }).to eq(1)
          end

          it 'still appends a score for each player whose value changed' do
            expect { interface.update_players }.to change(ExternalScore, :count).by(players.length)
          end
        end
      end

      describe 'when no adapter is injected' do
        let(:interface) { described_class.new(game:) }

        it 'raises an exception' do
          expect { interface.update_players }.to raise_error(ExternalData::Exception)
        end
      end
    end
  end

  describe 'tournaments' do
    let(:tournaments) do
      [
        { name: 'WC 2024', country: 'US', external_id: '/tournaments/1', starting_date: Faker::Date.forward },
        { name: 'Special Event Barcelona', country: 'ES', external_id: '/tournaments/2',
          starting_date: Faker::Date.forward }
      ].map { |attributes| ExternalData::Tournament.new(attributes:) }
    end

    describe '#upcoming_tournaments' do
      describe 'when an adapter is injected' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(upcoming_tournaments: tournaments)) }

        it 'retrieves all upcoming tournaments for the game' do
          expect(interface.upcoming_tournaments.map(&:instance_values)).to include(tournaments.sample.instance_values)
        end

        it 'includes a relation to the related game for the tournaments' do
          expect(interface.upcoming_tournaments.sample.game_id).to eq(game.id)
        end
      end

      describe 'when no adapter is injected' do
        let(:interface) { described_class.new(game:) }

        it 'raises an exception' do
          expect { interface.upcoming_tournaments }.to raise_error(ExternalData::Exception)
        end
      end
    end

    describe '#update_upcoming_tournaments' do
      describe 'when an adapter is injected' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(upcoming_tournaments: tournaments)) }

        describe 'when the tournament has been saved previously' do
          let(:tournament) { tournaments.sample }

          before do
            create(:tournament, **tournament.instance_values, starting_date: 2.days.from_now, game_id: game.id)
          end

          it 'updates the tournament information' do
            interface.update_upcoming_tournaments
            expect(Tournament.find_by(name: tournament.name).starting_date).to eq(tournament.starting_date)
          end

          it 'looks up the batch of existing tournaments in one query, not once per tournament' do
            expect(count_queries(pattern: /FROM "tournaments"/) { interface.update_upcoming_tournaments }).to eq(1)
          end
        end

        describe 'when the tournament data does not exist yet' do
          it 'saves the tournament information' do
            expect { interface.update_upcoming_tournaments }.to change(Tournament, :count).by(tournaments.length)
          end

          it 'returns how many tournaments were processed' do
            expect(interface.update_upcoming_tournaments).to eq(tournaments.length)
          end

          it 'looks up the batch of tournaments in one query, not once per tournament' do
            expect(count_queries(pattern: /FROM "tournaments"/) { interface.update_upcoming_tournaments }).to eq(1)
          end
        end
      end

      describe 'when no adapter is injected' do
        let(:interface) { described_class.new(game:) }

        it 'raises an exception' do
          expect { interface.update_upcoming_tournaments }.to raise_error(ExternalData::Exception)
        end
      end
    end
  end

  describe 'results' do
    let(:tournament) { create(:tournament, game:) }
    let(:results) do
      [
        { player_external_id: '/players/11', player_name: 'Test Player One', player_country: 'US', placement: 1 },
        { player_external_id: '/players/12', player_name: 'Test Player Two', player_country: 'CA', placement: 2 }
      ].map { |attributes| ExternalData::Result.new(attributes:) }
    end

    describe '#results' do
      describe 'when an adapter is injected' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(results:)) }

        it 'retrieves all the results for the tournament' do
          expect(interface.results(tournament:).map(&:placement)).to match_array(results.map(&:placement))
        end

        it 'includes a relation to the tournament for each result' do
          expect(interface.results(tournament:).sample.tournament).to eq(tournament)
        end
      end

      describe 'when no adapter is injected' do
        let(:interface) { described_class.new(game:) }

        it 'raises an exception' do
          expect { interface.results(tournament:) }.to raise_error(ExternalData::Exception)
        end
      end
    end

    describe '#update_results' do
      describe 'when an adapter is injected' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(results:)) }

        it 'creates a player for each result entry' do
          expect { interface.update_results(tournament:) }.to change(Player, :count).by(results.length)
        end

        it 'creates a result row for each entry' do
          expect { interface.update_results(tournament:) }.to change(Result, :count).by(results.length)
        end

        it 'returns how many results were processed' do
          expect(interface.update_results(tournament:)).to eq(results.length)
        end

        it 'sets the tournament field_size to the number of results processed' do
          interface.update_results(tournament:)

          expect(tournament.reload.field_size).to eq(results.length)
        end

        describe 'when called twice with the same fixture data' do
          before { interface.update_results(tournament:) }

          it 'does not create duplicate result rows' do
            expect { interface.update_results(tournament:) }.not_to change(Result, :count)
          end

          it 'does not create duplicate players' do
            expect { interface.update_results(tournament:) }.not_to change(Player, :count)
          end

          it 'leaves field_size unchanged' do
            interface.update_results(tournament:)

            expect(tournament.reload.field_size).to eq(results.length)
          end
        end
      end

      describe 'when every player of the batch already exists' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(results:)) }

        before do
          results.each { |result| create(:player, :without_scores, game:, external_id: result.player_external_id) }
        end

        it 'looks up the players of the batch in one query, not once per result' do
          expect(count_queries(pattern: /FROM "players"/) { interface.update_results(tournament:) }).to eq(1)
        end

        it 'looks up the existing result rows in one query on a second import' do
          interface.update_results(tournament:)

          expect(count_queries(pattern: /FROM "results"/) { interface.update_results(tournament:) }).to eq(1)
        end

        it 'still creates a result row for each entry' do
          expect { interface.update_results(tournament:) }.to change(Result, :count).by(results.length)
        end
      end

      describe 'when the adapter returns two results for the same new player' do
        let(:results) do
          [
            { player_external_id: '/players/21', player_name: 'One Player', player_country: 'US', placement: 1 },
            { player_external_id: '/players/21', player_name: 'One Player', player_country: 'US', placement: 2 }
          ].map { |attributes| ExternalData::Result.new(attributes:) }
        end
        let(:interface) { described_class.new(game:, adapter: fake_adapter(results:)) }

        it 'creates one player row, not one per result' do
          expect { interface.update_results(tournament:) }.to change(Player, :count).by(1)
        end

        it 'creates one result row, not one per result' do
          expect { interface.update_results(tournament:) }.to change(Result, :count).by(1)
        end
      end

      describe 'when the adapter returns no results' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(results: [])) }

        it 'does not set the tournament field_size' do
          interface.update_results(tournament:)

          expect(tournament.reload.field_size).to be_nil
        end
      end

      describe 'when one result cannot resolve or create a valid player' do
        let(:unresolvable_result) do
          ExternalData::Result.new(
            attributes: { player_external_id: '/players/13', player_name: nil, player_country: 'FR', placement: 3 }
          )
        end
        let(:interface) { described_class.new(game:, adapter: fake_adapter(results: results + [unresolvable_result])) }

        it 'still saves the results that are valid' do
          expect { interface.update_results(tournament:) }.to change(Result, :count).by(results.length)
        end

        it 'includes the failed result in field_size, since it still represents a real tournament entrant' do
          interface.update_results(tournament:)

          expect(tournament.reload.field_size).to eq(results.length + 1)
        end
      end

      describe 'when a field_size: override is given' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(results:)) }

        it 'sets the tournament field_size to the override, not the processed count' do
          interface.update_results(tournament:, field_size: 500)

          expect(tournament.reload.field_size).to eq(500)
        end

        describe 'when the adapter returns no results' do
          let(:interface) { described_class.new(game:, adapter: fake_adapter(results: [])) }

          it 'still sets field_size from the override' do
            interface.update_results(tournament:, field_size: 500)

            expect(tournament.reload.field_size).to eq(500)
          end
        end

        describe 'when the override is zero' do
          it 'falls back to the processed count instead of persisting a non-positive field_size' do
            interface.update_results(tournament:, field_size: 0)

            expect(tournament.reload.field_size).to eq(results.length)
          end
        end

        describe 'when the override is zero and there are also no results' do
          let(:interface) { described_class.new(game:, adapter: fake_adapter(results: [])) }

          it 'does not set field_size at all' do
            interface.update_results(tournament:, field_size: 0)

            expect(tournament.reload.field_size).to be_nil
          end
        end
      end

      describe 'when no field_size: override is given' do
        let(:interface) { described_class.new(game:, adapter: fake_adapter(results:)) }

        it 'preserves the existing computed-count behavior' do
          interface.update_results(tournament:)

          expect(tournament.reload.field_size).to eq(results.length)
        end
      end

      describe 'when no adapter is injected' do
        let(:interface) { described_class.new(game:) }

        it 'raises an exception' do
          expect { interface.update_results(tournament:) }.to raise_error(ExternalData::Exception)
        end
      end
    end
  end
end
