require 'rails_helper'

RSpec.describe 'Salary draft show', :js do
  it "shows the draft's tournament, price cap, and roster size" do
    game = create(:game)
    tournament = create(:tournament, game:, name: 'Winter Regionals')
    salary_draft = create(:salary_draft, tournament:, roster_size: 4, price_cap: 250)

    visit game_salary_draft_path(salary_draft, game:)

    within('table', text: tournament.name) do
      expect(page).to have_content(salary_draft.price_cap.to_s)
      expect(page).to have_content(salary_draft.roster_size.to_s)
    end
  end

  it 'offers no control to edit or remove the draft, even to an admin' do
    admin = create(:user, :with_role)
    game = create(:game)
    tournament = create(:tournament, game:)
    salary_draft = create(:salary_draft, tournament:)
    sign_in_with(admin)

    visit game_salary_draft_path(salary_draft, game:)

    within('#content') do
      expect(page).to have_no_link(href: %r{/edit\z})
      expect(page).to have_no_css("a[data-turbo-method='delete']")
    end
  end
end
