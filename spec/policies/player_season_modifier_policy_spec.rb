require 'rails_helper'

RSpec.describe PlayerSeasonModifierPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }
  let(:player_season_modifier) { create(:player_season_modifier) }

  permissions :create?, :destroy? do
    it { is_expected.not_to permit(user, player_season_modifier) }
    it { is_expected.to permit(admin, player_season_modifier) }
  end
end
