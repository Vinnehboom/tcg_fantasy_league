require 'rails_helper'

RSpec.describe 'SalaryDrafts' do
  let!(:game) { create(:game, id: 'PTCG') }
  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }

  before do
    sign_in user
  end

  describe '#index' do
    it 'shows all salary drafts' do
      get game_salary_drafts_path(game:)
      expect(response).to render_template('salary_drafts/index')
    end
  end

  describe '#show' do
    let(:salary_draft) { create(:salary_draft) }

    it 'shows the salary draft' do
      get game_salary_draft_path(salary_draft, game:)
      expect(response).to render_template('salary_drafts/show')
    end
  end

  describe '#edit' do
    before do
      sign_in admin
    end

    let(:salary_draft) { create(:salary_draft) }

    it 'shows the edit form' do
      get edit_game_salary_draft_path(salary_draft, game:)
      expect(response).to render_template('salary_drafts/edit')
    end
  end

  describe '#new' do
    before do
      sign_in admin
    end

    let(:salary_draft) { create(:salary_draft) }

    it 'shows the new form' do
      get new_game_salary_draft_path(game:)
      expect(response).to render_template('salary_drafts/new')
    end
  end

  describe '#create' do
    before do
      sign_in admin
    end

    describe 'when the information is complete' do
      let(:params) do
        {
          salary_draft: {
            tournament_id: create(:tournament, game:).id,
            roster_size: 5,
            price_cap: 200
          }
        }
      end

      it 'adds the draft to the platform' do
        expect { post game_salary_drafts_path(game:), params: }.to change(SalaryDraft, :count).by(1)
      end

      it 'show the new draft information' do
        post(game_salary_drafts_path(game:), params:)
        salary_draft = SalaryDraft.last
        expect(response).to redirect_to(game_salary_draft_path(salary_draft, game:))
      end
    end
  end

  describe '#update' do
    before do
      sign_in admin
    end

    let(:salary_draft) { create(:salary_draft, tournament: create(:tournament, game:), roster_size: 2) }

    describe 'when the information is complete' do
      let(:params) do
        {
          salary_draft: {
            roster_size: 5
          }
        }
      end

      it 'updates the draft' do
        expect(salary_draft.roster_size).to eq(2)
        put(game_salary_draft_path(salary_draft, game:), params:)
        expect(salary_draft.reload.roster_size).to eq(params[:salary_draft][:roster_size])
      end

      it 'show the draft information' do
        put(game_salary_draft_path(salary_draft, game:), params:)
        expect(response).to redirect_to(game_salary_draft_path(salary_draft, game:))
      end
    end
  end

  describe '#destroy' do
    before do
      sign_in admin
    end

    let(:salary_draft) { create(:salary_draft, tournament: create(:tournament, game:), roster_size: 2) }

    describe 'when the information is complete' do
      it 'deletes the draft' do
        expect(salary_draft.roster_size).to eq(2)
        delete(game_salary_draft_path(salary_draft, game:))
        expect(SalaryDraft.find_by(id: salary_draft.id)).to be_falsey
      end
    end
  end
end
