require 'rails_helper'

RSpec.describe Game do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:base_uri) }

  it { is_expected.to have_many(:players) }
  it { is_expected.to have_many(:tournaments) }

  describe '.upcoming_drafts' do
    subject { game.upcoming_drafts }

    let(:game) { create(:game) }

    let!(:passed_draft) { create(:salary_draft, tournament: create(:tournament, game:, starting_date: 1.day.ago)) }
    let!(:upcoming_draft) do
      create(:salary_draft, tournament: create(:tournament, game:, starting_date: 1.day.from_now))
    end

    it { is_expected.to include(upcoming_draft) }
    it { is_expected.not_to include(passed_draft) }
  end
end
