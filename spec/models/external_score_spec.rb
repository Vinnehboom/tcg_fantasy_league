require 'rails_helper'

RSpec.describe ExternalScore do
  it { is_expected.to belong_to(:player) }

  describe 'score validation' do
    subject(:save) { build(:external_score, player:, score:).save }

    let(:player) { create(:player) }
    let(:score) { 20 }

    context 'when score is present' do
      it { expect(save).to be_truthy }
    end

    context 'when score is missing' do
      let(:score) { nil }

      it { expect(save).to be_falsey }
    end

    context 'when the player already has a snapshot with the same score' do
      before do
        create(:external_score, player:, score:)
      end

      it 'allows the repeated snapshot' do
        expect(save).to be_truthy
      end
    end
  end
end
