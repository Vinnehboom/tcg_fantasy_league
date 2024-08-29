require 'rails_helper'

RSpec.describe SalaryDraftsController do
  let(:game) { create(:game, name: 'PTCG') }

  describe '#index' do
    it 'shows the available drafts for all upcoming tournaments' do
      tournament, tournament2 = create_list(:tournament, 2, game:)
      tournament.update(starting_date: 2.days.ago)
      draft = create(:salary_draft, tournament:)
      draft2 = create(:salary_draft, tournament: tournament2)
      get :index, params: { game: game.name }
      expect(assigns(:salary_drafts)).to include(draft2)
      expect(assigns(:salary_drafts)).not_to include(draft)
    end
  end
end
