require 'rails_helper'

RSpec.describe ScoreModifierPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }
  let(:score_modifier) { create(:multiplier) }

  permissions :new?, :edit?, :create?, :update?, :destroy? do
    it { is_expected.not_to permit(user, score_modifier) }
    it { is_expected.to permit(admin, score_modifier) }
  end
end
