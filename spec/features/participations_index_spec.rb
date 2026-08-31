require 'rails_helper'

RSpec.describe 'Participations index', :js do
  let(:game) { create(:game) }
  let(:other_game) { create(:game) }
  let(:user) { create(:user, password: 'testtest') }
  let(:other_user) { create(:user) }
  let(:tournament) { create(:tournament, game:, name: 'My Winter Regionals') }
  let(:other_users_tournament) { create(:tournament, game:, name: "Someone Else's Regionals") }
  let(:own_other_game_tournament) { create(:tournament, game: other_game, name: 'My Other Game Regionals') }

  before do
    create(:participation, user:, draft: create(:salary_draft, tournament:))
    create(:participation, user: other_user, draft: create(:salary_draft, tournament: other_users_tournament))
    create(:participation, user:, draft: create(:salary_draft, tournament: own_other_game_tournament))
  end

  it "shows the signed-in user's own participation in this game, not another user's or another game's" do
    sign_in_with(user)
    visit game_participations_path(game:)

    expect(page).to have_content(tournament.name)
    expect(page).to have_no_content(other_users_tournament.name)
    expect(page).to have_no_content(own_other_game_tournament.name)
  end
end
