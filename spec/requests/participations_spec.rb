require 'rails_helper'

RSpec.describe 'Participations' do
  let!(:game) { create(:game, id: 'PTCG') }
  let(:user) { create(:user) }
  let(:admin) { create(:user, :with_role, role: :admin) }

  before do
    sign_in user
  end

  describe '#index' do
    it 'shows all participations' do
      get game_participations_path(game:)
      expect(response).to render_template('participations/index')
    end
  end

  describe '#show' do
    let(:participation) { create(:participation, user:) }

    it 'shows the participation' do
      get game_participation_path(participation, game:)
      expect(response).to render_template('participations/show')
    end
  end

  describe '#create' do
    before do
      sign_in user
    end

    describe 'when the information is complete' do
      let(:params) do
        {
          participation: {
            draft_id: create(:salary_draft).id,
            user_id: user.id
          }
        }
      end

      it 'adds the participation to the platform' do
        expect { post game_participations_path(game:), params: }.to change(Participation, :count).by(1)
      end

      it 'show the new participation information' do
        post(game_participations_path(game:), params:)
        participation = Participation.last
        expect(response).to redirect_to(game_participation_path(id: participation.id, game:))
      end
    end
  end

  describe '#update' do
    let(:participation) { create(:participation, user:) }

    before do
      sign_in user
    end

    describe 'when submitting the participation' do
      let(:params) do
        {
          participation: {
            status: 'submitted'
          }
        }
      end

      context 'when the participation has completed rosters' do
        before do
          create(:roster, :with_players, participation:)
        end

        it 'submits the participation' do
          patch(game_participation_path(id: participation.id, game:), params:)
          expect(participation.reload).to be_submitted
        end

        it 'show the participation' do
          patch(game_participation_path(id: participation.id, game:), params:)
          expect(response).to redirect_to(game_participation_path(id: participation.id, game:))
        end
      end

      context 'when the rosters are empty' do
        before do
          participation.rosters.destroy_all
        end

        it 'does not submit the participation' do
          patch(game_participation_path(id: participation.id, game:), params:)
          expect(participation.reload).not_to be_submitted
        end

        it 'show the participation' do
          patch(game_participation_path(id: participation.id, game:), params:)
          expect(response).to redirect_to(game_participation_path(id: participation.id, game:))
        end
      end
    end
  end

  describe '#destroy' do
    before do
      sign_in admin
    end

    let(:participation) { create(:participation, user:) }

    describe 'when the information is complete' do
      it 'deletes the draft' do
        delete(game_participation_path(participation, game:))
        expect(Participation.find_by(id: participation.id)).to be_falsey
      end
    end
  end
end
