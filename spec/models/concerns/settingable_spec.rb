require 'rails_helper'

RSpec.describe Settingable do
  # A second, independent includer, backed by the same table shape as
  # GameSetting. Proves the behavior below comes from the concern itself,
  # not something only GameSetting happens to do.
  let(:record_class) do
    Class.new(ApplicationRecord) do
      self.table_name = 'game_settings'
      include Settingable

      def self.name
        'SettingableTestRecord'
      end
    end
  end

  it { is_expected.to be_a(Module) }

  describe 'validations' do
    subject(:record) { record_class.new(settingable: create(:season)) }

    it { is_expected.to validate_presence_of(:settings) }
  end

  describe 'uniqueness' do
    subject(:duplicate) { record_class.new(settingable: existing.settingable, settings: { 'a' => 1 }) }

    let(:existing) { record_class.create!(settingable: create(:season), settings: { 'a' => 1 }) }

    before { existing }

    it 'rejects a second row for the same settingable' do
      expect(duplicate).not_to be_valid
    end
  end

  describe '.for' do
    subject(:looked_up) { record_class.for(settingable: season) }

    let(:season) { create(:season) }

    context 'when the settingable has no row and the includer does not override nearest_prior' do
      it 'returns nil rather than carrying anything forward' do
        expect(looked_up).to be_nil
      end
    end

    context 'when the settingable has its own row' do
      before { record_class.create!(settingable: season, settings: { 'a' => 1 }) }

      it 'returns that row' do
        expect(looked_up.settings).to eq({ 'a' => 1 })
      end
    end
  end
end
