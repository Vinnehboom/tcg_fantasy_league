require 'rails_helper'

RSpec.describe 'Roster edit', :js do
  it 'adds a player to the roster through the turbo-stream update, updating the live price and cap display' do
    game = create(:game)
    tournament = create(:tournament, game:, starting_date: 1.year.from_now)
    salary_draft = create(:salary_draft, tournament:, roster_size: 3, price_cap: 250)
    user = create(:user, password: 'testtest')
    roster = create(:roster, participation: create(:participation, user:, draft: salary_draft))
    player = create(:player, :without_scores, game:, name: 'Ash Ketchum')
    create(:external_score, player:, score: 5)

    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'testtest'
    click_button I18n.t('devise.sessions.sign_in')
    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    visit edit_game_roster_path(id: roster.id, game:)

    within('#player_table') { click_link I18n.t('rosters.edit.add_player') }

    within("#roster_#{roster.id}") do
      expect(page).to have_content(player.name)
      expect(page).to have_css('tr', text: "1 / #{salary_draft.roster_size}")
      expect(page).to have_css('tr', text: "#{roster.reload.total_cost} / #{salary_draft.price_cap}")
    end
    within('#player_table') { expect(page).to have_no_content(player.name) }
  end

  it 'removes a player from the roster through the turbo-stream update' do
    game = create(:game)
    tournament = create(:tournament, game:, starting_date: 1.year.from_now)
    salary_draft = create(:salary_draft, tournament:, roster_size: 3, price_cap: 250)
    user = create(:user, password: 'testtest')
    roster = create(:roster, participation: create(:participation, user:, draft: salary_draft))
    player = create(:player, :without_scores, game:, name: 'Ash Ketchum')
    create(:external_score, player:, score: 5)
    create(:roster_player, roster:, player:)

    visit new_user_session_path
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: 'testtest'
    click_button I18n.t('devise.sessions.sign_in')
    expect(page).to have_content(I18n.t('devise.sessions.signed_in'))
    visit edit_game_roster_path(id: roster.id, game:)

    within("#roster_#{roster.id}") { click_link I18n.t('rosters.edit.remove_player') }

    within("#roster_#{roster.id}") do
      expect(page).to have_no_content(player.name)
      expect(page).to have_css('tr', text: "0 / #{salary_draft.roster_size}")
    end
  end
end
