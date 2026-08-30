require 'rails_helper'

RSpec.describe 'Salary drafts index', :js do
  it "lists the game's upcoming salary drafts, not its past ones" do
    game = create(:game)
    tournament = create(:tournament, game:, name: 'Winter Regionals', starting_date: 1.year.from_now)
    salary_draft = create(:salary_draft, tournament:, roster_size: 4, price_cap: 250)
    past_tournament = create(:tournament, game:, name: "Last Year's Regionals", starting_date: 1.year.ago)
    create(:salary_draft, tournament: past_tournament, roster_size: 4, price_cap: 250)

    visit game_salary_drafts_path(game:)

    expect(page).to have_content(tournament.name)
    expect(page).to have_no_content(past_tournament.name)
    within('tr', text: tournament.name) do
      expect(page).to have_content(salary_draft.roster_size.to_s)
      expect(page).to have_content(salary_draft.price_cap.to_s)
    end
  end
end
