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
