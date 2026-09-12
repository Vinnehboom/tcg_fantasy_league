require 'rails_helper'

RSpec.describe 'Roster show', :js do
  it "shows the roster's tournament and its players" do
    game = create(:game)
    tournament = create(:tournament, game:, name: 'Winter Regionals')
    salary_draft = create(:salary_draft, tournament:)
    user = create(:user, password: 'testtest')
    participation = create(:participation, user:, draft: salary_draft)
    roster = create(:roster, participation:)
    player = create(:player, :without_scores, game:, name: 'Ash Ketchum')
    create(:external_score, player:, score: 5)
    create(:roster_player, roster:, player:)

    sign_in_with(user)
    visit game_roster_path(id: roster.id, game:)

    within('table', text: tournament.name) do
      expect(page).to have_content(tournament.name)
      expect(page).to have_content(player.name)
      expect(page).to have_content(player.current_score.to_s)
    end
  end

  it 'shows a suppressed roster player as a placeholder, never by their real name' do
    game = create(:game)
    tournament = create(:tournament, game:, name: 'Winter Regionals')
    salary_draft = create(:salary_draft, tournament:)
    user = create(:user, password: 'testtest')
    participation = create(:participation, user:, draft: salary_draft)
    roster = create(:roster, participation:)
    suppressed_player = create(:player, :without_scores, :suppressed, game:, name: 'Ash Ketchum')
    create(:roster_player, roster:, player: suppressed_player)

    sign_in_with(user)
    visit game_roster_path(id: roster.id, game:)

    within('table', text: tournament.name) do
      expect(page).to have_content(I18n.t('players.suppressed_display_name'))
      expect(page).to have_no_content('Ash Ketchum')
    end
  end
end
