require 'rails_helper'

RSpec.describe 'Roster show', :js do
  it "shows the roster's tournament and its players" do
    game = create(:game)
    tournament = create(:tournament, game:, name: 'Winter Regionals')
    salary_draft = create(:salary_draft, tournament:)
    user = create(:user, password: 'testtest')
    participation = create(:participation, user:, draft: salary_draft)
    roster = create(:roster, participation:)
    player = create(:player, :without_scores, game:, name: 'Ash Ketchum')
    create(:external_score, player:, score: 5)
    create(:roster_player, roster:, player:)

    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'testtest'
    click_button I18n.t('devise.sessions.sign_in')
    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    visit game_roster_path(id: roster.id, game:)

    within('table', text: tournament.name) do
      expect(page).to have_content(tournament.name)
      expect(page).to have_content(player.name)
      expect(page).to have_content(player.current_score.to_s)
    end
  end
end
