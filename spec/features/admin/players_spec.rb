require 'rails_helper'

RSpec.describe 'Admin players' do
  let(:admin) { create(:user, :with_role) }

  before { sign_in_with(admin) }

  describe 'show' do
    it 'attaches a modifier to a player' do
      player = create(:player, name: 'Ash Ketchum')
      player_season = player.player_seasons.first
      create(:multiplier, name: 'hot streak')

      visit admin_player_path(player)
      select 'hot streak', from: "player_season_modifier_score_modifier_id_#{player_season.id}"
      click_button I18n.t('admin.players.show.attach')

      # The attach action is headless (no redirect) - see it took effect by
      # loading the page again, not by expecting it to update on its own.
      visit admin_player_path(player)

      expect(page).to have_css('td', exact_text: 'hot streak')
    end

    it 'takes a modifier away from a player' do
      player = create(:player, name: 'Ash Ketchum')
      player_season = player.player_seasons.first
      score_modifier = create(:multiplier, name: 'hot streak')
      create(:player_season_modifier, player_season:, score_modifier:)

      visit admin_player_path(player)
      expect(page).to have_css('td', exact_text: 'hot streak')

      click_link I18n.t('admin.players.show.detach')

      # Headless again - reload to see the result.
      visit admin_player_path(player)

      expect(page).to have_content('No score modifier attached yet.')
    end
  end
end
