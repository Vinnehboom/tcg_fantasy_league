require 'rails_helper'

RSpec.describe TournamentPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }
  let(:tournament) { create(:tournament) }

  permissions :update? do
    it { is_expected.not_to permit(user, tournament) }
    it { is_expected.to permit(admin, tournament) }
  end
end
