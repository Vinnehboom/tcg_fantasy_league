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

    it 'shows a suppressed roster player as a placeholder, never by their real name' do
      other_tournament = create(:tournament, game:, name: 'Autumn Cup')
      other_participation = create(
        :participation, user:, draft: create(:salary_draft, tournament: other_tournament), status: 'completed'
      )
      suppressed_player = create(:player, :without_scores, :suppressed, game:, name: 'Brock Harrison')
      score_roster(participation: other_participation, score: 5, player: suppressed_player)

      sign_in_with(user)
      visit game_user_path(id: user.id, game:)

      within('tr', text: other_tournament.name) do
        expect(page).to have_content(I18n.t('players.suppressed_display_name'))
        expect(page).to have_no_content('Brock Harrison')
      end
    end
  end

  context 'when a participation is not completed' do
    let(:game) { create(:game) }
    let(:tournament) { create(:tournament, game:, name: 'Winter Regionals') }
    let(:user) { create(:user, password: 'testtest') }
    let(:completed) { create(:participation, user:, draft: create(:salary_draft, tournament:), status: 'completed') }
    let(:other_tournament) { create(:tournament, game:, name: 'Spring Invitational') }
    let(:submitted_draft) { create(:salary_draft, tournament: other_tournament) }
    let(:submitted) { create(:participation, user:, draft: submitted_draft, status: 'submitted') }

    before do
      score_roster(participation: completed, score: 25)
      score_roster(participation: submitted, score: 5)
    end

    it 'excludes a roster from the list when its participation is not completed' do
      sign_in_with(user)
      visit game_user_path(id: user.id, game:)

      expect(page).to have_css('tr', text: tournament.name)
      expect(page).to have_no_content(other_tournament.name)
    end

    it "still counts a not-completed participation's score toward the highscore" do
      sign_in_with(user)
      visit game_user_path(id: user.id, game:)

      within('tr', text: 'Lifetime highscore') { expect(page).to have_css('td', exact_text: '30.0') }
    end
  end

  context "when a signed-in user views another user's profile" do
    it "shows the other user's username, highscore, and roster, but hides their email" do
      game = create(:game)
      tournament = create(:tournament, game:, name: 'Winter Regionals')
      draft = create(:salary_draft, tournament:)
      viewer = create(:user, password: 'testtest')
      profile_user = create(:user)
      participation = create(:participation, user: profile_user, draft:, status: 'completed')
      player = create(:player, :without_scores, game:, name: 'Ash Ketchum')
      score_roster(participation:, score: 10, player:)

      sign_in_with(viewer)
      visit game_user_path(id: profile_user.id, game:)

      within('tr', text: 'Username') { expect(page).to have_css('td', exact_text: profile_user.username) }
      within('tr', text: 'Lifetime highscore') { expect(page).to have_css('td', exact_text: '10.0') }
      within('tr', text: tournament.name) do
        expect(page).to have_content(player.name)
        expect(page).to have_css('td', exact_text: '10.0')
        expect(page).to have_css('td.text-center', exact_text: '10.0')
      end
      expect(page).to have_no_content(profile_user.email)
    end
  end

  context "when a signed-in admin views another user's profile" do
    it "shows the regular user's email" do
      game = create(:game)
      admin = create(:user, :with_role, password: 'testtest')
      regular_user = create(:user)

      sign_in_with(admin)
      visit game_user_path(id: regular_user.id, game:)

      expect(page).to have_content('User profile')
      expect(page).to have_css('td', exact_text: regular_user.email)
    end
  end
end
