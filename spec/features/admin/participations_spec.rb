require 'rails_helper'

RSpec.describe 'Admin participations' do
  let(:admin) { create(:user, :with_role) }

  before { sign_in_as(admin) }

  describe 'index' do
    it 'lists participations by user and tournament' do
      participation = create(:participation)

      visit admin_participations_path

      expect(page).to have_content(participation.user.username)
      expect(page).to have_content(participation.tournament.name)
    end
  end

  describe 'show' do
    it 'shows the draft, tournament, and roster details' do
      participation = create(:participation, :with_roster)

      visit admin_participation_path(participation)

      expect(page).to have_content(participation.game.name)
      expect(page).to have_link(participation.tournament.name)
      expect(page).to have_content(participation.draft.price_cap)
      expect(page).to have_content(participation.draft.roster_size)
      expect(page).to have_content(participation.rosters.first.players.first.name)
    end

    it 'shows a suppressed roster player as a placeholder, never by their real name' do
      participation = create(:participation)
      roster = create(:roster, participation:)
      suppressed_player = create(:player, :without_scores, :suppressed, name: 'Ash Ketchum')
      create(:roster_player, roster:, player: suppressed_player)

      visit admin_participation_path(participation)

      expect(page).to have_content(I18n.t('players.suppressed_display_name'))
      expect(page).to have_no_content('Ash Ketchum')
    end
  end
end
