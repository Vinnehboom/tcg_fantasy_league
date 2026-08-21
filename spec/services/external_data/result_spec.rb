module ExternalData

  RSpec.describe Result do
    let(:game) { create(:game) }
    let(:tournament) { create(:tournament, game:) }

    it_behaves_like 'PersistableObjectInterface', described_class

    def build_result(player_external_id: '/players/9', player_name: 'New Player', player_country: 'BE', placement: 1)
      result = described_class.new(attributes: { player_external_id:, player_name:, player_country:, placement: })
      result.tournament = tournament
      result
    end

    describe '#save!' do
      describe 'when no player exists for that external_id and game yet' do
        it 'creates the player' do
          expect { build_result.save! }.to change(::Player, :count).by(1)
        end

        it 'stamps the created player with the scraped name and country' do
          build_result(player_name: 'New Player', player_country: 'BE').save!

          player = ::Player.find_by(external_id: '/players/9', game_id: game.id)
          expect(player).to have_attributes(name: 'New Player', country: 'BE')
        end

        it 'creates a result row with the given placement' do
          build_result(placement: 3).save!

          player = ::Player.find_by(external_id: '/players/9', game_id: game.id)
          expect(::Result.find_by(player:, tournament:).placement).to eq(3)
        end
      end

      describe 'when a player already exists for that external_id and game' do
        let(:existing_player) do
          create(:player, external_id: '/players/9', game:, name: 'Existing Player', country: 'FR')
        end

        before { existing_player }

        it 'does not create a new player' do
          expect { build_result(player_name: 'Scraped Name').save! }.not_to change(::Player, :count)
        end

        it 'does not overwrite the existing player name or country' do
          build_result(player_name: 'Scraped Name', player_country: 'ES').save!

          expect(existing_player.reload).to have_attributes(name: 'Existing Player', country: 'FR')
        end
      end

      describe 'when saved twice for the same player and tournament' do
        it 'does not create a duplicate result row' do
          build_result(placement: 5).save!

          expect { build_result(placement: 5).save! }.not_to change(::Result, :count)
        end

        it 'updates the placement rather than leaving the stale one' do
          build_result(placement: 5).save!
          build_result(placement: 1).save!

          player = ::Player.find_by(external_id: '/players/9', game_id: game.id)
          expect(::Result.find_by(player:, tournament:).placement).to eq(1)
        end
      end

      describe 'when the scraped data cannot produce a valid player' do
        it 'raises instead of silently dropping the result' do
          expect { build_result(player_name: nil).save! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

end
