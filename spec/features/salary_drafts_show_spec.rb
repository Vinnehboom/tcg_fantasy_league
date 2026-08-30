require 'rails_helper'

RSpec.describe 'Salary draft show', :js do
  it "shows the draft's tournament, price cap, and roster size" do
    game = create(:game)
    tournament = create(:tournament, game:, name: 'Winter Regionals')
    salary_draft = create(:salary_draft, tournament:, roster_size: 4, price_cap: 250)

    visit game_salary_draft_path(salary_draft, game:)

    expect(page).to have_content(tournament.name)
    expect(page).to have_content(salary_draft.price_cap.to_s)
    expect(page).to have_content(salary_draft.roster_size.to_s)
  end
end
