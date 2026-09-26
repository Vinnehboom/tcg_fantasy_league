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
end
