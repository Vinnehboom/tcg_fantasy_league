module ExternalData

  RSpec.describe PersistableObject do
    let(:game) { create(:game, id: 'PTCG') }
    let(:example_class) { ::Player }
    let(:example_persistable_class) { ExternalData::Player }
    let(:external_id) { 1 }
    let(:example_persistable_instance) do
      example_persistable_class.new(attributes: { game_id: game.id, external_id: }.merge(attributes))
    end

    describe '#save!' do
      let(:attributes) do
        {
          name: 'New player',
          country: 'BE'
        }
      end

      describe 'when the record does not exist yet' do
        it 'creates the record with the given data' do
          expect { example_persistable_instance.save! }.to change(example_class, :count).by(1)
        end
      end

      describe 'when there is already a record for the given game and external id' do
        before do
          create(:player, game:, external_id:)
        end

        it 'does not create a new record' do
          expect { example_persistable_instance.save! }.not_to change(example_class, :count)
        end

        it 'updates the record' do
          example_persistable_instance.save!
          expect(example_class.find_by(external_id:, game:).name).to eq('New player')
        end
      end
    end
  end

end
