require 'rails_helper'

RSpec.describe 'Roster edit', :js do
  def build_roster_for_edit(price_cap: 250, roster_size: 3)
    game = create(:game)
    tournament = create(:tournament, game:, starting_date: 1.year.from_now)
    salary_draft = create(:salary_draft, tournament:, roster_size:, price_cap:)
    user = create(:user, password: 'testtest')
    roster = create(:roster, participation: create(:participation, user:, draft: salary_draft))
    Struct.new(:game, :salary_draft, :user, :roster, keyword_init: true).new(game:, salary_draft:, user:, roster:)
  end

  it 'adds a player to the roster through the turbo-stream update, updating the live price and cap display' do
    edit_page = build_roster_for_edit
    player = create(:player, :without_scores, game: edit_page.game, name: 'Ash Ketchum')
    create(:external_score, player:, score: 5)

    sign_in_with(edit_page.user)
    visit edit_game_roster_path(id: edit_page.roster.id, game: edit_page.game)

    within('#player_table') { click_link I18n.t('rosters.edit.add_player') }

    within("#roster_#{edit_page.roster.id}") do
      expect(page).to have_content(player.name)
      expect(page).to have_css('tr', text: "1 / #{edit_page.salary_draft.roster_size}")
      expect(page).to have_css('tr', text: '1.0 / 250')
    end
    within('#player_table') { expect(page).to have_no_content(player.name) }
  end

  it 'removes a player from the roster through the turbo-stream update' do
    edit_page = build_roster_for_edit
    player = create(:player, :without_scores, game: edit_page.game, name: 'Ash Ketchum')
    create(:external_score, player:, score: 5)
    create(:roster_player, roster: edit_page.roster, player:)

    sign_in_with(edit_page.user)
    visit edit_game_roster_path(id: edit_page.roster.id, game: edit_page.game)

    within("#roster_#{edit_page.roster.id}") { click_link I18n.t('rosters.edit.remove_player') }

    within("#roster_#{edit_page.roster.id}") do
      expect(page).to have_no_content(player.name)
      expect(page).to have_css('tr', text: "0 / #{edit_page.salary_draft.roster_size}")
    end
  end

  it 'shows a suppressed roster player as a placeholder, with the name and cost masked' do
    edit_page = build_roster_for_edit
    suppressed_player = create(:player, :without_scores, :suppressed, game: edit_page.game, name: 'Ash Ketchum')
    create(:external_score, player: suppressed_player, score: 500)
    create(:roster_player, roster: edit_page.roster, player: suppressed_player)

    sign_in_with(edit_page.user)
    visit edit_game_roster_path(id: edit_page.roster.id, game: edit_page.game)

    within("#roster_#{edit_page.roster.id}") do
      expect(page).to have_content(I18n.t('players.suppressed_display_name'))
      expect(page).to have_no_content('Ash Ketchum')
      expect(page).to have_css('td', exact_text: '—')
      expect(page).to have_css('tr', text: "1 / #{edit_page.salary_draft.roster_size}")
      expect(page).to have_css('tr', text: '40.0 / 250')
    end
  end

  it 'rejects a pick that would exceed the price cap, and keeps the player available' do
    edit_page = build_roster_for_edit(price_cap: 0)
    player = create(:player, :without_scores, game: edit_page.game, name: 'Ash Ketchum')
    create(:external_score, player:, score: 5)

    sign_in_with(edit_page.user)
    visit edit_game_roster_path(id: edit_page.roster.id, game: edit_page.game)

    within('#player_table') { click_link I18n.t('rosters.edit.add_player') }

    expect(page).to have_content('Roster failed to update.')
    within("#roster_#{edit_page.roster.id}") do
      expect(page).to have_css('tr', text: "0 / #{edit_page.salary_draft.roster_size}")
    end
    within('#player_table') { expect(page).to have_content(player.name) }
  end
end
