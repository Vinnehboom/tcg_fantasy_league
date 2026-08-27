require 'rails_helper'

RSpec.describe 'Game home page', :js do
  it "shows the game's upcoming drafts and top scoring users" do
    game = create(:game)
    tournament = create(:tournament, game:, name: 'Regional Championship')
    salary_draft = create(:salary_draft, tournament:)
    scoring_user = create(:user, username: 'top-scorer')
    player = create(:player, game:)
    participation = create(:participation, user: scoring_user, draft: salary_draft)
    roster = create(:roster, participation:)
    create(:roster_player, roster:, player:, score: 42)

    visit game_root_path(game:)

    expect(page).to have_content(I18n.t('pages.home.upcoming_drafts'))
    expect(page).to have_content(tournament.name)
    expect(page).to have_content(I18n.t('pages.home.top_players'))
    expect(page).to have_content(scoring_user.username)
  end
end
