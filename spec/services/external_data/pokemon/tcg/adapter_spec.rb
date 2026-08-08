require 'rails_helper'

RSpec.describe ExternalData::Pokemon::Tcg::Adapter do
  subject(:adapter) { described_class.new }

  it_behaves_like 'an external data adapter'

  describe '#players' do
    it 'delegates to Pokemon::Tcg::Players' do
      allow(ExternalData::Pokemon::Tcg::Players).to receive(:all).and_return(:players)

      expect(adapter.players).to eq(:players)
    end
  end

  describe '#upcoming_tournaments' do
    it 'delegates to Pokemon::Tcg::Tournaments' do
      allow(ExternalData::Pokemon::Tcg::Tournaments).to receive(:upcoming_tournaments).and_return(:tournaments)

      expect(adapter.upcoming_tournaments).to eq(:tournaments)
    end
  end
end
