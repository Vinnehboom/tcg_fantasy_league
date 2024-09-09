require 'rails_helper'

module Admin

  RSpec.describe 'SalaryDrafts' do
    before do
      sign_in admin
    end

    let(:admin) { create(:user, :with_role, role: :admin) }

    describe '#show' do
      it 'shows the draft' do
        get admin_salary_draft_path(create(:salary_draft))
        expect(response).to render_template('admin/salary_drafts/show')
      end
    end

    describe '#index' do
      it 'shows all drafts' do
        get admin_salary_drafts_path
        expect(response).to render_template('admin/salary_drafts/index')
      end
    end

    describe '#edit' do
      let(:salary_draft) { create(:salary_draft) }

      it 'shows the edit form' do
        get edit_admin_salary_draft_path(salary_draft)
        expect(response).to render_template('admin/salary_drafts/edit')
      end
    end

    describe '#new' do
      let(:salary_draft) { create(:salary_draft) }

      it 'shows the new form' do
        get new_admin_salary_draft_path
        expect(response).to render_template('admin/salary_drafts/new')
      end
    end

    describe '#create' do
      describe 'when the information is complete' do
        let(:params) do
          {
            salary_draft: {
              tournament_id: create(:tournament).id,
              roster_size: 5,
              price_cap: 200
            }
          }
        end

        it 'adds the draft to the platform' do
          expect { post admin_salary_drafts_path, params: }.to change(SalaryDraft, :count).by(1)
        end

        it 'show the new draft information' do
          post(admin_salary_drafts_path, params:)
          salary_draft = SalaryDraft.last
          expect(response).to redirect_to(admin_salary_draft_path(salary_draft))
        end
      end
    end

    describe '#update' do
      let(:salary_draft) { create(:salary_draft, tournament: create(:tournament), roster_size: 2) }

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
          put(admin_salary_draft_path(salary_draft), params:)
          expect(salary_draft.reload.roster_size).to eq(params[:salary_draft][:roster_size])
        end

        it 'show the draft information' do
          put(admin_salary_draft_path(salary_draft), params:)
          expect(response).to redirect_to(admin_salary_draft_path(salary_draft))
        end
      end
    end

    describe '#destroy' do
      let(:salary_draft) { create(:salary_draft, tournament: create(:tournament), roster_size: 2) }

      describe 'when the information is complete' do
        it 'deletes the draft' do
          expect(salary_draft.roster_size).to eq(2)
          delete(admin_salary_draft_path(salary_draft))
          expect(SalaryDraft.find_by(id: salary_draft.id)).to be_falsey
        end
      end
    end
  end

end
