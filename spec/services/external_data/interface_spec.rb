require 'rails_helper'

RSpec.describe ExternalData::Interface do
  let(:game) { create(:game) }
  let(:interface) { described_class.new(game:) }

  describe 'players' do
    let(:players) do
      [
        { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791' },
        { name: 'Efrain Herman', country: 'MQ', external_id: '/players/6', external_points: '399' },
        { name: 'Guadalupe Ernser', country: 'MF', external_id: '/players/7', external_points: '460' },
        { name: 'Janyce Gusikowski V', country: 'DO', external_id: '/players/8', external_points: '163' }
      ].map { |attributes| ExternalData::Player.new(attributes:) }
    end

    describe '#players' do
      describe 'when a game with a corresponding adapter is given' do
        before do
          allow(ExternalData::OfflineAdapter).to receive(:players).and_return(players)
        end

        it 'retrieves all the players for the game' do
          expect(interface.players.map(&:instance_values)).to include(players.sample.instance_values)
        end

        it 'includes a relation to the related game for the players' do
          expect(interface.players.sample.game_id).to eq(game.id)
        end
      end

      describe 'when a game without a corresponding adapter is given' do
        it 'raises an exception' do
          expect { interface.players }.to raise_error(ExternalData::Exception)
        end
      end
    end

    describe '#update_players' do
      describe 'when a game with a corresponding adapter is given' do
        before do
          allow(ExternalData::OfflineAdapter).to receive(:players).and_return(players)
        end

        describe 'when the player data exists' do
          let(:player) { players.sample }
          let!(:db_player) { create(:player, **player.instance_values.slice!('external_points'), game_id: game.id) }

          it 'updates the players information' do
            interface.update_players
            expect(Player.find_by(name: player.name).country).to eq(player.country)
          end

          describe 'when the external score has been updated' do
            it 'creates a new score' do
              allow(ExternalData::OfflineAdapter).to receive(:players).and_return([player])
              expect { interface.update_players }.to change(ExternalScore, :count).by(1)
            end
          end

          describe 'when the external score has not changed' do
            it 'creates a new score' do
              create(:external_score, player: db_player, score: player.external_points)
              allow(ExternalData::OfflineAdapter).to receive(:players).and_return([player])
              expect { interface.update_players }.not_to change(ExternalScore, :count)
            end
          end
        end

        describe 'when the players data does not exist yet' do
          it 'saves the players information' do
            expect { interface.update_players }.to change(Player, :count).by(players.length)
          end
        end
      end

      describe 'when a game without a corresponding adapter is given' do
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
      describe 'when a game with a corresponding adapter is given' do
        before do
          allow(ExternalData::OfflineAdapter).to receive(:upcoming_tournaments).and_return(tournaments)
        end

        it 'retrieves all upcoming tournaments for the game' do
          expect(interface.upcoming_tournaments.map(&:instance_values)).to include(tournaments.sample.instance_values)
        end

        it 'includes a relation to the related game for the tournaments' do
          expect(interface.upcoming_tournaments.sample.game_id).to eq(game.id)
        end
      end

      describe 'when a game without a corresponding adapter is given' do
        it 'raises an exception' do
          expect { interface.upcoming_tournaments }.to raise_error(ExternalData::Exception)
        end
      end
    end

    describe '#update_upcoming_tournaments' do
      describe 'when a game with a corresponding adapter is given' do
        before do
          allow(ExternalData::OfflineAdapter).to receive(:upcoming_tournaments).and_return(tournaments)
        end

        describe 'when the tournament has been saved previously' do
          let(:tournament) { tournaments.sample }

          before do
            create(:tournament, **tournament.instance_values, starting_date: 2.days.from_now, game_id: game.id)
          end

          it 'updates the tournament information' do
            interface.update_upcoming_tournaments
            expect(Tournament.find_by(name: tournament.name).starting_date).to eq(tournament.starting_date)
          end
        end

        describe 'when the tournament data does not exist yet' do
          it 'saves the tournament information' do
            expect { interface.update_upcoming_tournaments }.to change(Tournament, :count).by(tournaments.length)
          end
        end
      end

      describe 'when a game without a corresponding adapter is given' do
        it 'raises an exception' do
          expect { interface.update_upcoming_tournaments }.to raise_error(ExternalData::Exception)
        end
      end
    end
  end
end
