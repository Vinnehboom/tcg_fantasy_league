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
      record_class.register(:widget, id: 'WIDGET', adapter: ->(game:) { "adapter for #{game.id}" },
                                     results_verifier: ->(id) { id }, results_import_job: String)
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

    describe '#results_import_job' do
      subject(:job_class) { record.results_import_job }

      context 'when the row matches a registered id' do
        let(:record) { record_class.create!(id: 'WIDGET', name: 'Widget', base_uri: 'https://example.com') }

        it 'returns the collaborator registered for that id' do
          expect(job_class).to eq(String)
        end
      end

      context 'when the row has an unregistered id' do
        let(:record) { record_class.create!(id: 'OTHER', name: 'Other', base_uri: 'https://example.com') }

        it 'returns nil' do
          expect(job_class).to be_nil
        end
      end
    end

    describe '#adapter' do
      subject(:adapter) { record.adapter }

      context 'when the row matches a registered id' do
        let(:record) { record_class.create!(id: 'WIDGET', name: 'Widget', base_uri: 'https://example.com') }

        it 'builds the collaborator registered for that id, passing itself as game' do
          expect(adapter).to eq('adapter for WIDGET')
        end
      end

      context 'when the row has an unregistered id' do
        let(:record) { record_class.create!(id: 'OTHER', name: 'Other', base_uri: 'https://example.com') }

        it 'returns nil' do
          expect(adapter).to be_nil
        end
      end
    end

    describe '#results_verifier' do
      subject(:verifier) { record.results_verifier }

      context 'when the row matches a registered id' do
        let(:record) { record_class.create!(id: 'WIDGET', name: 'Widget', base_uri: 'https://example.com') }

        it 'returns the collaborator registered for that id' do
          expect(verifier.call('anything')).to eq('anything')
        end
      end

      context 'when the row has an unregistered id' do
        let(:record) { record_class.create!(id: 'OTHER', name: 'Other', base_uri: 'https://example.com') }

        it 'returns nil' do
          expect(verifier).to be_nil
        end
      end
    end
  end
end
