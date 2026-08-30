require 'rails_helper'

RSpec.describe 'Participation show', :js do
  it "shows the draft's details and the participation's roster" do
    game = create(:game)
    tournament = create(:tournament, game:, name: 'Winter Regionals')
    salary_draft = create(:salary_draft, tournament:, roster_size: 3, price_cap: 250)
    user = create(:user, password: 'testtest')
    participation = create(:participation, user:, draft: salary_draft)
    roster = create(:roster, participation:)
    player = create(:player, game:, name: 'Ash Ketchum')
    create(:roster_player, roster:, player:)

    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'testtest'
    click_button I18n.t('devise.sessions.sign_in')
    visit game_participation_path(participation, game:)

    expect(page).to have_content(tournament.name)
    expect(page).to have_content(salary_draft.price_cap.to_s)
    expect(page).to have_content(salary_draft.roster_size.to_s)
    expect(page).to have_content(player.name)
    expect(page).to have_content('1 / 3')
  end
end
