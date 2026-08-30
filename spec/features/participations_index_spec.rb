require 'rails_helper'

RSpec.describe 'Participations index', :js do
  it "shows the signed-in user's own participation, not another user's" do
    game = create(:game)
    user = create(:user, password: 'testtest')
    other_user = create(:user)
    tournament = create(:tournament, game:, name: 'My Winter Regionals')
    other_tournament = create(:tournament, game:, name: 'Someone Else\'s Regionals')
    draft = create(:salary_draft, tournament:)
    other_draft = create(:salary_draft, tournament: other_tournament)
    create(:participation, user:, draft:)
    create(:participation, user: other_user, draft: other_draft)

    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'testtest'
    click_button I18n.t('devise.sessions.sign_in')
    visit game_participations_path(game:)

    expect(page).to have_no_content(other_tournament.name)
    expect(page).to have_content(tournament.name)
  end
end
