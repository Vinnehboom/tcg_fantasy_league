require 'rails_helper'

RSpec.describe ExternalData::Interface do
  let(:game) { create(:game) }
  let(:interface) { described_class.new(game) }

  describe '#players' do
    let(:players) do
      [
        { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791' },
        { name: 'Efrain Herman', country: 'MQ', external_id: '/players/6', external_points: '399' },
        { name: 'Guadalupe Ernser', country: 'MF', external_id: '/players/7', external_points: '460' },
        { name: 'Janyce Gusikowski V', country: 'DO', external_id: '/players/8', external_points: '163' }
      ]
    end

    describe 'when a game with a corresponding adapter is given' do
      before do
        allow(ExternalData::OfflineAdapter).to receive(:players).and_return(players)
      end

      it 'retrieves all the players for the game' do
        expect(interface.players.to_s).to include(*players.sample.values.map(&:to_s))
      end

      it 'includes a relation to the related game for the players' do
        expect(interface.players.sample[:game_id]).to eq(game.id)
      end
    end

    describe 'when a game without a corresponding adapter is given' do
      it 'raises an exception' do
        expect { interface.players }.to raise_error(ExternalData::Exception)
      end
    end
  end

  describe '#update_players' do
    let(:players) do
      [
        { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791' },
        { name: 'Efrain Herman', country: 'MQ', external_id: '/players/6', external_points: '399' },
        { name: 'Guadalupe Ernser', country: 'MF', external_id: '/players/7', external_points: '460' },
        { name: 'Janyce Gusikowski V', country: 'DO', external_id: '/players/8', external_points: '163' }
      ]
    end

    describe 'when a game with a corresponding adapter is given' do
      before do
        allow(ExternalData::OfflineAdapter).to receive(:players).and_return(players)
      end

      describe 'when the player data exists' do
        let(:player) { players.sample }

        before do
          create(:player, **player, external_points: '100', game_id: game.id)
        end

        it 'updates the players information' do
          interface.update_players
          expect(Player.find_by(name: player[:name]).external_points).to eq(player[:external_points])
        end
      end

      describe 'when the players data does not exist yet' do
        it 'saves the players information' do
          expect { interface.update_players }.to change(Player, :count).by(4)
        end
      end
    end

    describe 'when a game without a corresponding adapter is given' do
      it 'raises an exception' do
        expect { interface.update_players }.to raise_error(ExternalData::Exception)
      end
    end
  end

  describe '#update_players' do
    let(:players) do
      [
        { name: 'Jodie Predovic', country: 'TF', external_id: '/players/5', external_points: '791' },
        { name: 'Efrain Herman', country: 'MQ', external_id: '/players/6', external_points: '399' },
        { name: 'Guadalupe Ernser', country: 'MF', external_id: '/players/7', external_points: '460' },
        { name: 'Janyce Gusikowski V', country: 'DO', external_id: '/players/8', external_points: '163' }
      ]
    end

    describe 'when a game with a corresponding adapter is given' do
      before do
        allow(ExternalData::OfflineAdapter).to receive(:players).and_return(players)
      end

      describe 'when the player data exists' do
        let(:player) { players.sample }

        before do
          create(:player, **player, external_points: '100', game_id: game.id)
        end

        it 'updates the players information' do
          interface.update_players
          expect(Player.find_by(name: player[:name]).external_points).to eq(player[:external_points])
        end
      end

      describe 'when the players data does not exist yet' do
        it 'saves the players information' do
          expect { interface.update_players }.to change(Player, :count).by(4)
        end
      end
    end

    describe 'when a game without a corresponding adapter is given' do
      it 'raises an exception' do
        expect { interface.update_players }.to raise_error(CustomException)
      end
    end
  end
end
