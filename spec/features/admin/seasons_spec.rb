require 'rails_helper'

RSpec.describe 'Admin seasons' do
  let(:admin) { create(:user, :with_role) }

  before { sign_in_with(admin) }

  describe 'index' do
    it 'reaches the seasons of a game from the game page' do
      game = create(:game, :ptcg)
      create(:season, game:, label: 'Pokemon 2026')

      visit admin_game_path(game)
      click_link 'Seasons'

      expect(page).to have_css('td', exact_text: 'Pokemon 2026')
    end

    it 'lists the seasons of a Riftbound game, with an open season shown as open' do
      game = create(:game, id: 'RIFT')
      create(:season, game:, label: 'Riftbound 1', start_date: Date.new(2026, 1, 1), end_date: nil)

      visit admin_game_seasons_path(game)

      within('tr', text: 'Riftbound 1') do
        expect(page).to have_css('td', exact_text: '01-01-2026')
        expect(page).to have_css('td', exact_text: 'Open')
      end
    end
  end

  describe 'new' do
    it 'creates an open season for a game from a label and a start date' do
      game = create(:game, id: 'RIFT')

      visit admin_game_seasons_path(game)
      click_link 'New season'
      fill_in 'season_label', with: 'Riftbound 1'
      fill_in 'season_start_date', with: '2026-01-01'
      click_button 'Create Season'

      expect(page).to have_content('Season successfully created.')
      within('tr', text: 'Riftbound 1') do
        expect(page).to have_css('td', exact_text: 'Open')
      end
    end

    it 'refuses a second open season for the same game' do
      game = create(:game, :ptcg)
      create(:season, game:, start_date: Date.new(2025, 9, 1), end_date: nil)

      visit new_admin_game_season_path(game)
      fill_in 'season_label', with: 'Pokemon 2027'
      fill_in 'season_start_date', with: '2026-09-01'
      click_button 'Create Season'

      expect(page).to have_content('overlaps an existing season for this game')
    end
  end

  describe 'edit' do
    it 'closes the open season, then opens the next one' do
      game = create(:game, :ptcg)
      create(:season, game:, label: 'Pokemon 2026', start_date: Date.new(2025, 9, 1), end_date: nil)

      visit admin_game_seasons_path(game)
      within('tr', text: 'Pokemon 2026') { click_link 'Edit' }
      fill_in 'season_end_date', with: '2026-08-31'
      click_button 'Update Season'
      click_link 'New season'
      fill_in 'season_label', with: 'Pokemon 2027'
      fill_in 'season_start_date', with: '2026-09-01'
      click_button 'Create Season'

      within('tr', text: 'Pokemon 2026') do
        expect(page).to have_css('td', exact_text: '31-08-2026')
      end
      within('tr', text: 'Pokemon 2027') do
        expect(page).to have_css('td', exact_text: 'Open')
      end
    end
  end
end
