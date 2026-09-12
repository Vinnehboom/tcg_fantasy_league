require 'rails_helper'

RSpec.describe Result do
  it { is_expected.to belong_to(:player) }
  it { is_expected.to belong_to(:tournament) }
  it { is_expected.to validate_presence_of(:placement) }

  describe '#player, when the player is suppressed' do
    it 'still resolves to the player instead of nil' do
      player = create(:player, :suppressed)
      result = create(:result, player:)

      expect(result.reload.player).to eq(player)
    end
  end

  describe 'uniqueness' do
    subject { build(:result, player:, tournament:).save }

    let(:player) { create(:player) }
    let(:tournament) { create(:tournament) }

    context 'when the player does not have a result in the tournament' do
      it { is_expected.to be_truthy }
    end

    context 'when another player has a result in the tournament' do
      before do
        create(:result, player: create(:player), tournament:)
      end

      it { is_expected.to be_truthy }
    end

    context 'when the player already has a result in a different tournament' do
      before do
        create(:result, player:, tournament: create(:tournament))
      end

      it { is_expected.to be_truthy }
    end

    context 'when the player already has a result in the tournament' do
      before do
        create(:result, player:, tournament:)
      end

      it { is_expected.to be_falsey }
    end
  end
end
