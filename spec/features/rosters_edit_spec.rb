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

    sign_in_with(user)
    visit edit_game_roster_path(id: roster.id, game:)

    within('#player_table') { click_link I18n.t('rosters.edit.add_player') }

    within("#roster_#{roster.id}") do
      expect(page).to have_content(player.name)
      expect(page).to have_css('tr', text: "1 / #{salary_draft.roster_size}")
      expect(page).to have_css('tr', text: '1.0 / 250')
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

    sign_in_with(user)
    visit edit_game_roster_path(id: roster.id, game:)

    within("#roster_#{roster.id}") { click_link I18n.t('rosters.edit.remove_player') }

    within("#roster_#{roster.id}") do
      expect(page).to have_no_content(player.name)
      expect(page).to have_css('tr', text: "0 / #{salary_draft.roster_size}")
    end
  end

  it 'shows a suppressed roster player as a placeholder, never by their real name' do
    game = create(:game)
    tournament = create(:tournament, game:, starting_date: 1.year.from_now)
    salary_draft = create(:salary_draft, tournament:, roster_size: 3, price_cap: 250)
    user = create(:user, password: 'testtest')
    roster = create(:roster, participation: create(:participation, user:, draft: salary_draft))
    suppressed_player = create(:player, :without_scores, :suppressed, game:, name: 'Ash Ketchum')
    create(:roster_player, roster:, player: suppressed_player)

    sign_in_with(user)
    visit edit_game_roster_path(id: roster.id, game:)

    within("#roster_#{roster.id}") do
      expect(page).to have_content(I18n.t('players.suppressed_display_name'))
      expect(page).to have_no_content('Ash Ketchum')
    end
  end

  it 'rejects a pick that would exceed the price cap, and keeps the player available' do
    game = create(:game)
    tournament = create(:tournament, game:, starting_date: 1.year.from_now)
    salary_draft = create(:salary_draft, tournament:, roster_size: 3, price_cap: 0)
    user = create(:user, password: 'testtest')
    roster = create(:roster, participation: create(:participation, user:, draft: salary_draft))
    player = create(:player, :without_scores, game:, name: 'Ash Ketchum')
    create(:external_score, player:, score: 5)

    sign_in_with(user)
    visit edit_game_roster_path(id: roster.id, game:)

    within('#player_table') { click_link I18n.t('rosters.edit.add_player') }

    expect(page).to have_content('Roster failed to update.')
    within("#roster_#{roster.id}") { expect(page).to have_css('tr', text: "0 / #{salary_draft.roster_size}") }
    within('#player_table') { expect(page).to have_content(player.name) }
  end
end
