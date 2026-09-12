require 'rails_helper'

module ExternalData

  RSpec.describe Player do
    it_behaves_like 'PersistableObjectInterface', described_class

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
        expect { scraped_player.save! }.not_to change(::Player.unscoped, :count)
      end

      it 'does not update the existing player\'s attributes' do
        scraped_player.save!

        expect(suppressed_player.reload).to have_attributes(name: 'Existing Player', country: 'FR')
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
