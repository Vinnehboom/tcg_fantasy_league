require 'rails_helper'

RSpec.describe 'User profile', :js do
  def score_roster(participation:, score:, player: create(:player))
    create(:roster_player, roster: create(:roster, participation:), player:, score:)
  end

  context 'when a user views their own profile' do
    let(:user) { create(:user, password: 'testtest') }
    let(:game) { create(:game) }
    let(:tournament_a) { create(:tournament, game:, name: 'Winter Regionals') }
    let(:tournament_b) { create(:tournament, game:, name: 'Summer Championships') }
    let(:participation_a) do
      create(:participation, user:, draft: create(:salary_draft, tournament: tournament_a), status: 'completed')
    end
    let(:participation_b) do
      create(:participation, user:, draft: create(:salary_draft, tournament: tournament_b), status: 'completed')
    end
    let(:player_a) { create(:player, :without_scores, game:, name: 'Ash Ketchum') }
    let(:player_b) { create(:player, :without_scores, game:, name: 'Misty Waterflower') }

    before do
      score_roster(participation: participation_a, score: 10, player: player_a)
      score_roster(participation: participation_b, score: 15, player: player_b)
    end

    it 'shows the username, email, and lifetime highscore' do
      sign_in_with(user)
      visit game_user_path(id: user.id, game:)

      expect(page).to have_content('My profile')
      within('tr', text: 'Username') { expect(page).to have_css('td', exact_text: user.username) }
      within('tr', text: 'Email') { expect(page).to have_css('td', exact_text: user.email) }
      within('tr', text: 'Lifetime highscore') { expect(page).to have_css('td', exact_text: '25.0') }
    end

    it "lists all completed rosters' tournaments" do
      sign_in_with(user)
      visit game_user_path(id: user.id, game:)

      expect(page).to have_css('tr', text: tournament_a.name)
      expect(page).to have_css('tr', text: tournament_b.name)
    end

    it "shows a roster's player name, score, and participation score" do
      sign_in_with(user)
      visit game_user_path(id: user.id, game:)

      within('tr', text: tournament_a.name) do
        expect(page).to have_content(player_a.name)
        expect(page).to have_css('td', exact_text: '10.0')
        expect(page).to have_css('td.text-center', exact_text: '10.0')
      end
    end
  end
end
