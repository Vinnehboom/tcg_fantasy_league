require 'rails_helper'

RSpec.describe 'Admin salary drafts' do
  let(:admin) { create(:user, :with_role) }

  before { sign_in_as(admin) }

  describe 'index' do
    it 'lists drafts by tournament and links to a new one' do
      salary_draft = create(:salary_draft)

      visit admin_salary_drafts_path

      expect(page).to have_content(salary_draft.tournament.name)
      expect(page).to have_link(I18n.t('admin.salary_drafts.index.add'), href: new_admin_salary_draft_path)
    end
  end

  describe 'new' do
    it 'creates a draft for an upcoming tournament' do
      tournament = create(:tournament, starting_date: 1.day.from_now)

      visit new_admin_salary_draft_path
      select("#{tournament.game.id} - #{tournament.name}", from: 'salary_draft_tournament_id')
      fill_in 'salary_draft_roster_size', with: 3
      fill_in 'salary_draft_price_cap', with: 500
      click_button I18n.t('helpers.submit.create', model: 'Salary draft')

      expect(page).to have_content(tournament.name)
      expect(page).to have_content('3')
      expect(page).to have_content('500')
    end

    it 'creates a draft that requires 18+ to participate' do
      tournament = create(:tournament, starting_date: 1.day.from_now)

      visit new_admin_salary_draft_path
      select("#{tournament.game.id} - #{tournament.name}", from: 'salary_draft_tournament_id')
      fill_in 'salary_draft_roster_size', with: 3
      fill_in 'salary_draft_price_cap', with: 500
      select 'eighteen_plus', from: 'salary_draft_minimum_age'
      click_button I18n.t('helpers.submit.create', model: 'Salary draft')

      expect(SalaryDraft.last).to be_eighteen_plus
    end
  end

  describe 'edit' do
    it "updates a draft's price cap" do
      salary_draft = create(:salary_draft)

      visit edit_admin_salary_draft_path(salary_draft)
      fill_in 'salary_draft_price_cap', with: 750
      click_button I18n.t('helpers.submit.update', model: 'Salary draft')

      expect(page).to have_content('750')
    end

    it 'flips a draft to requiring 18+' do
      salary_draft = create(:salary_draft, minimum_age: :unrestricted)

      visit edit_admin_salary_draft_path(salary_draft)
      select 'eighteen_plus', from: 'salary_draft_minimum_age'
      click_button I18n.t('helpers.submit.update', model: 'Salary draft')

      expect(salary_draft.reload).to be_eighteen_plus
    end
  end

  describe 'show' do
    it 'shows the draft details and action buttons' do
      tournament = create(:tournament, starting_date: 1.day.ago)
      salary_draft = create(:salary_draft, tournament:)

      visit admin_salary_draft_path(salary_draft)

      expect(page).to have_content(salary_draft.tournament.name)
      expect(page).to have_content(salary_draft.price_cap)
      expect(page).to have_content(salary_draft.roster_size)
      expect(page).to have_link(I18n.t('admin.salary_drafts.show.edit'))
      expect(page).to have_link(I18n.t('admin.salary_drafts.show.complete'))
    end

    it 'shows a suppressed roster player as a placeholder, never by their real name' do
      salary_draft = create(:salary_draft)
      participation = create(:participation, draft: salary_draft, status: 'submitted')
      roster = create(:roster, participation:)
      suppressed_player = create(:player, :without_scores, :suppressed, name: 'Ash Ketchum')
      create(:roster_player, roster:, player: suppressed_player)

      visit admin_salary_draft_path(salary_draft)

      expect(page).to have_content(I18n.t('players.suppressed_display_name'))
      expect(page).to have_no_content('Ash Ketchum')
    end
  end

  describe 'complete' do
    it 'scores submitted participations and marks them completed' do
      tournament = create(:tournament, starting_date: 1.day.ago)
      salary_draft = create(:salary_draft, tournament:)
      participation = create(:participation, :with_roster, draft: salary_draft, status: 'submitted')

      visit admin_salary_draft_path(salary_draft)
      click_link I18n.t('admin.salary_drafts.show.complete')

      expect(page).to have_current_path(admin_salary_draft_path(salary_draft))
      expect(participation.reload).to be_completed
    end
  end
end
