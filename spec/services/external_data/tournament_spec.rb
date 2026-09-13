require 'rails_helper'

module ExternalData

  RSpec.describe Tournament do
    it_behaves_like 'PersistableObjectInterface', described_class

    describe '.preload' do
      let(:game) { create(:game) }
      let!(:existing_tournament) { create(:tournament, game:, external_id: '/tournaments/1', name: 'Existing') }
      let(:existing_object) do
        described_class.new(attributes: { game_id: game.id, external_id: '/tournaments/1', name: 'Scraped' })
      end
      let(:new_object) do
        described_class.new(attributes: { game_id: game.id, external_id: '/tournaments/2', name: 'Brand New' })
      end

      before { described_class.preload([existing_object, new_object]) }

      it 'resolves an existing tournament without a further query' do
        expect(count_queries(pattern: /FROM "tournaments"/) { existing_object.send(:existing_record) }).to eq(0)
        expect(existing_object.send(:existing_record)).to eq(existing_tournament)
      end

      it 'resolves a brand new tournament to nil without a further query' do
        expect(count_queries(pattern: /FROM "tournaments"/) { new_object.send(:existing_record) }).to eq(0)
        expect(new_object.send(:existing_record)).to be_nil
      end
    end
  end

end
