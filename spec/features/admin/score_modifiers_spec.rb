require 'rails_helper'

RSpec.describe 'Admin score modifiers' do
  let(:admin) { create(:user, :with_role) }

  before { sign_in_with(admin) }

  describe 'new' do
    it 'creates a multiplier from a name and a value' do
      visit new_admin_score_modifier_path

      select I18n.t('activerecord.models.multiplier.one'), from: 'score_modifier_type'
      select 'hot streak', from: 'score_modifier_name'
      fill_in 'score_modifier_value', with: '1.5'
      click_button I18n.t('helpers.submit.create', model: 'Score modifier')

      expect(page).to have_content('Score modifier successfully created.')
      expect(page).to have_css('td', exact_text: 'hot streak')
      expect(page).to have_css('td', exact_text: 'Multiplier')
    end

    it 'creates a bonus from a name and a value' do
      visit new_admin_score_modifier_path

      select I18n.t('activerecord.models.bonus.one'), from: 'score_modifier_type'
      select 'winner', from: 'score_modifier_name'
      fill_in 'score_modifier_value', with: '5'
      click_button I18n.t('helpers.submit.create', model: 'Score modifier')

      expect(page).to have_css('td', exact_text: 'Bonus')
    end
  end

  describe 'show' do
    it 'takes a modifier away from a player' do
      player = create(:player, name: 'Ash Ketchum')
      player_season = player.player_seasons.first
      score_modifier = create(:multiplier, name: 'legend')
      create(:player_season_modifier, player_season:, score_modifier:)

      visit admin_score_modifier_path(score_modifier)

      expect(page).to have_css('td', exact_text: 'Ash Ketchum')

      click_link 'Detach'

      # The detach action is headless (no redirect) - see it took effect by
      # loading the page again, not by expecting it to update on its own.
      visit admin_score_modifier_path(score_modifier)

      expect(page).to have_no_css('td', exact_text: 'Ash Ketchum')
    end
  end
end
