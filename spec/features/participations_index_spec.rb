require 'rails_helper'

RSpec.describe 'Participations index', :js do
  it "shows the signed-in user's own participation in this game, not another user's or another game's" do
    game = create(:game)
    other_game = create(:game)
    user = create(:user, password: 'testtest')
    other_user = create(:user)
    tournament = create(:tournament, game:, name: 'My Winter Regionals')
    other_users_tournament = create(:tournament, game:, name: "Someone Else's Regionals")
    own_other_game_tournament = create(:tournament, game: other_game, name: 'My Other Game Regionals')
    create(:participation, user:, draft: create(:salary_draft, tournament:))
    create(:participation, user: other_user, draft: create(:salary_draft, tournament: other_users_tournament))
    create(:participation, user:, draft: create(:salary_draft, tournament: own_other_game_tournament))

    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'testtest'
    click_button I18n.t('devise.sessions.sign_in')
    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    visit game_participations_path(game:)

    expect(page).to have_content(tournament.name)
    expect(page).to have_no_content(other_users_tournament.name)
    expect(page).to have_no_content(own_other_game_tournament.name)
  end
end
