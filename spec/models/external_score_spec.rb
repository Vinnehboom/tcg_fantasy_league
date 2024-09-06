require 'rails_helper'

RSpec.describe ExternalScore do
  it { is_expected.to belong_to(:player) }

  describe 'unique score validation' do
    subject { build(:external_score, player:, score:).save }

    let(:player) { create(:player) }
    let(:score) { 20 }

    context 'when the player does not have a score of the same value' do
      it { is_expected.to be_truthy }
    end

    context 'when another player has a score of the same value' do
      before do
        create(:external_score, player: create(:player), score:)
      end

      it { is_expected.to be_truthy }
    end

    context 'when the player has a score of the same value' do
      before do
        create(:external_score, player:, score:)
      end

      it { is_expected.to be_falsey }
    end
  end
end
