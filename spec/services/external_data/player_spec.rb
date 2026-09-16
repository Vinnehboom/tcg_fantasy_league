require 'rails_helper'

module ExternalData

  RSpec.describe Player do
    it_behaves_like 'PersistableObjectInterface', described_class

    describe '.preload' do
      let(:game) { create(:game) }
      let!(:existing_player) { create(:player, game:, external_id: '/players/1', name: 'Existing') }
      let(:existing_object) do
        described_class.new(attributes: { game_id: game.id, external_id: '/players/1', name: 'Scraped' })
      end
      let(:new_object) do
        described_class.new(attributes: { game_id: game.id, external_id: '/players/2', name: 'Brand New' })
      end

      before { described_class.preload([existing_object, new_object]) }

      it 'resolves an existing player without a further query' do
        expect(count_queries(pattern: /FROM "players"/) { existing_object.send(:existing_record) }).to eq(0)
        expect(existing_object.send(:existing_record)).to eq(existing_player)
      end

      it 'resolves a brand new player to nil without a further query' do
        expect(count_queries(pattern: /FROM "players"/) { new_object.send(:existing_record) }).to eq(0)
        expect(new_object.send(:existing_record)).to be_nil
      end
    end

    describe '.preload, for the player season and its latest score' do
      let(:game) { create(:game) }
      let(:season) { create(:season, game:) }
      let(:existing_player) { create(:player, :without_scores, game:, external_id: '/players/1') }
      let(:player_season) { create(:player_season, player: existing_player, season:) }
      let(:existing_object) do
        described_class.new(
          attributes: { game_id: game.id, external_id: '/players/1', name: 'Scraped', external_points: 300, season: }
        )
      end
      let(:new_object) do
        described_class.new(
          attributes: { game_id: game.id, external_id: '/players/2', name: 'Brand New', external_points: 300, season: }
        )
      end

      def resolved_player_season(object, record)
        object.send(:player_season, record:)
      end

      before do
        create(:external_score, player_season:, score: 250)
        described_class.preload([existing_object, new_object])
      end

      it 'resolves the player season of an existing player without a further query' do
        counted = count_queries(pattern: /FROM "player_seasons"/) do
          resolved_player_season(existing_object, existing_player)
        end

        expect(counted).to eq(0)
        expect(resolved_player_season(existing_object, existing_player)).to eq(player_season)
      end

      it 'resolves the latest score of an existing player without a further query' do
        resolved = resolved_player_season(existing_object, existing_player)

        expect(count_queries(pattern: /FROM "external_scores"/) { resolved.latest_score }).to eq(0)
        expect(resolved.latest_score).to eq(250)
      end

      it 'reads no score row while it creates the player season of a brand new player' do
        expect(count_queries(pattern: /FROM "external_scores"/) { new_object.save! }).to eq(0)
      end

      it 'still records the score of a brand new player' do
        new_object.save!

        expect(::Player.find_by(external_id: '/players/2', game_id: game.id).current_score).to eq(300)
      end
    end

    describe '.preload, when the batch repeats an external id' do
      let(:game) { create(:game) }
      let(:season) { create(:season, game:) }
      let(:repeated_objects) do
        ['First name', 'Second name'].map do |name|
          described_class.new(
            attributes: { game_id: game.id, external_id: '/players/3', name:, external_points: 400, season: }
          )
        end
      end

      before { described_class.preload(repeated_objects) }

      it 'creates one player for the batch, not one per object' do
        expect { repeated_objects.each(&:save!) }.to change(::Player, :count).by(1)
      end

      it 'creates one player season for the batch, not one per object' do
        expect { repeated_objects.each(&:save!) }.to change(::PlayerSeason, :count).by(1)
      end

      it 'records the score once, because the second object sees the first one as unchanged' do
        expect { repeated_objects.each(&:save!) }.to change(::ExternalScore, :count).by(1)
      end
    end

    describe '#save!, when a player already exists and is suppressed' do
      let(:game) { create(:game) }
      let(:season) { create(:season) }
      let!(:suppressed_player) do
        create(:player, :suppressed, game:, external_id: '/players/9', name: 'Existing Player', country: 'FR')
      end
      let(:scraped_player) do
        described_class.new(
          attributes: {
            game_id: game.id, external_id: '/players/9', name: 'Scraped Name', country: 'ES',
            external_points: 500, season:
          }
        )
      end

      it 'does not create a new player row' do
        expect { scraped_player.save! }.not_to change(::Player, :count)
      end

      it 'does not update the existing player\'s attributes' do
        scraped_player.save!

        expect(suppressed_player.reload).to have_attributes(raw_name: 'Existing Player', country: 'FR')
      end

      it 'does not record a new score' do
        expect { scraped_player.save! }.not_to change(ExternalScore, :count)
      end

      it 'returns false' do
        expect(scraped_player.save!).to be false
      end
    end
  end

end
