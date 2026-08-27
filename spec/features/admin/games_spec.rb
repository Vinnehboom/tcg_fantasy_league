require 'rails_helper'

RSpec.describe 'Admin games' do
  let(:admin) { create(:user, :with_role) }
  let(:game) { create(:game) }

  before { sign_in_as(admin) }

  describe 'index' do
    it 'lists games with a link to each one' do
      game

      visit admin_games_path

      expect(page).to have_content(game.name)
      expect(page).to have_link(href: admin_game_path(game))
    end
  end

  describe 'show' do
    it "shows the game's details and import actions" do
      visit admin_game_path(game)

      expect(page).to have_content(game.id)
      expect(page).to have_content(game.name)
      expect(page).to have_button(I18n.t('admin.games.show.trigger_players'))
      expect(page).to have_button(I18n.t('admin.games.show.trigger_tournaments'))
    end
  end
end
