require 'rails_helper'

RSpec.describe 'SalaryDrafts' do
  let!(:game) { create(:game, name: 'PTCG') }

  describe '#index' do
    it 'shows all salary drafts' do
      get game_salary_drafts_path(game: game.name)
      expect(response).to render_template('salary_drafts/index')
    end
  end

  describe '#show' do
    let(:salary_draft) { create(:salary_draft) }

    it 'shows the salary draft' do
      get game_salary_draft_path(salary_draft, game: game.name)
      expect(response).to render_template('salary_drafts/show')
    end
  end
end
