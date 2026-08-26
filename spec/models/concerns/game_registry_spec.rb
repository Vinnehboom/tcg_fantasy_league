require 'rails_helper'

RSpec.describe GameRegistry do
  # A second, independent includer, backed by the same table shape as Game.
  # Proves the behavior below comes from the concern itself, not something
  # only Game happens to do.
  let(:record_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'games'
      include GameRegistry

      def self.name
        'GameRegistryTestRecord'
      end
    end
  end

  it { is_expected.to be_a(Module) }

  describe '.register' do
    before do
      record_class.register(:widget, id: 'WIDGET', results_source_id_url_pattern: /\A(?<results_source_id>\d+)\z/)
    end

    describe 'the generated scope' do
      context 'when a row with the registered id exists' do
        before { record_class.create!(id: 'WIDGET', name: 'Widget', base_uri: 'https://example.com') }

        it 'finds that row' do
          expect(record_class.widget.id).to eq('WIDGET')
        end
      end

      context 'when no row with the registered id exists' do
        it 'returns nil' do
          expect(record_class.widget).to be_nil
        end
      end
    end

    describe '#results_source_id_url_pattern' do
      subject(:pattern) { record.results_source_id_url_pattern }

      context 'when the row matches a registered id' do
        let(:record) { record_class.create!(id: 'WIDGET', name: 'Widget', base_uri: 'https://example.com') }

        it 'returns the pattern registered for that id' do
          expect(pattern).to eq(/\A(?<results_source_id>\d+)\z/)
        end
      end

      context 'when the row has an unregistered id' do
        let(:record) { record_class.create!(id: 'OTHER', name: 'Other', base_uri: 'https://example.com') }

        it 'returns nil' do
          expect(pattern).to be_nil
        end
      end
    end
  end
end
