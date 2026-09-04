require 'rails_helper'

module Admin

  RSpec.describe 'ScoreModifiers' do
    let(:admin) { create(:user, :with_role, role: :admin) }

    before do
      sign_in admin
    end

    describe '#index' do
      it 'renders the index template' do
        get admin_score_modifiers_path

        expect(response).to render_template('admin/score_modifiers/index')
      end

      context 'when modifiers exist' do
        it "lists each modifier's name, linked to its show page" do
          score_modifier = create(:multiplier, name: 'winner')

          get admin_score_modifiers_path

          expect(response.body).to include('winner')
          expect(response.body).to include(admin_score_modifier_path(score_modifier))
        end
      end

      context 'when there are no modifiers' do
        it 'renders an empty state' do
          get admin_score_modifiers_path

          expect(response.body).to include('No score modifiers found yet.')
        end
      end

      context 'when a modifier has been discarded' do
        it 'excludes it from the list' do
          score_modifier = create(:multiplier, name: 'legend')
          score_modifier.discard

          get admin_score_modifiers_path

          expect(response.body).not_to include('legend')
        end
      end
    end

    describe '#show' do
      it 'renders the show template' do
        get admin_score_modifier_path(create(:bonus))

        expect(response).to render_template('admin/score_modifiers/show')
      end

      context 'when the modifier has been discarded' do
        it 'is not found' do
          score_modifier = create(:bonus)
          score_modifier.discard

          get admin_score_modifier_path(score_modifier)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe '#new' do
      it 'renders the new template' do
        get new_admin_score_modifier_path

        expect(response).to render_template('admin/score_modifiers/new')
      end
    end

    describe '#edit' do
      it 'renders the edit template' do
        get edit_admin_score_modifier_path(create(:multiplier))

        expect(response).to render_template('admin/score_modifiers/edit')
      end

      context 'when the modifier has been discarded' do
        it 'is not found' do
          score_modifier = create(:multiplier)
          score_modifier.discard

          get edit_admin_score_modifier_path(score_modifier)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe '#create' do
      context 'when the kind is a multiplier' do
        let(:params) { { score_modifier: { type: 'Multiplier', name: 'hot streak', value: '1.5' } } }

        it 'adds the modifier to the platform' do
          expect { post admin_score_modifiers_path, params: }.to change(Multiplier, :count).by(1)
        end

        it 'shows the new modifier' do
          post(admin_score_modifiers_path, params:)

          expect(response).to redirect_to(admin_score_modifier_path(ScoreModifier.last))
        end
      end

      context 'when the kind is a bonus' do
        let(:params) { { score_modifier: { type: 'Bonus', name: 'winner', value: '5' } } }

        it 'adds the modifier to the platform' do
          expect { post admin_score_modifiers_path, params: }.to change(Bonus, :count).by(1)
        end
      end

      context 'when the kind is not one the platform offers' do
        let(:params) { { score_modifier: { type: 'User', name: 'legend', value: '1' } } }

        it 'creates nothing' do
          expect { post admin_score_modifiers_path, params: }.not_to change(ScoreModifier, :count)
        end

        it 'shows the form again' do
          post(admin_score_modifiers_path, params:)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'when the name is missing' do
        let(:params) { { score_modifier: { type: 'Bonus', name: '', value: '5' } } }

        it 'creates nothing' do
          expect { post admin_score_modifiers_path, params: }.not_to change(ScoreModifier, :count)
        end
      end

      context 'when the name is not one the platform offers' do
        let(:params) { { score_modifier: { type: 'Bonus', name: 'Sneaky', value: '5' } } }

        it 'creates nothing' do
          expect { post admin_score_modifiers_path, params: }.not_to change(ScoreModifier, :count)
        end

        it 'shows the form again' do
          post(admin_score_modifiers_path, params:)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe '#update' do
      let(:score_modifier) { create(:multiplier, name: 'hot streak', value: 2) }

      it 'renames the modifier' do
        put admin_score_modifier_path(score_modifier),
            params: { score_modifier: { type: 'Multiplier', name: 'winner', value: '2' } }

        expect(score_modifier.reload.name).to eq('winner')
      end

      it 'shows the modifier again' do
        put admin_score_modifier_path(score_modifier),
            params: { score_modifier: { type: 'Multiplier', name: 'winner', value: '2' } }

        expect(response).to redirect_to(admin_score_modifier_path(score_modifier))
      end

      it 'turns a multiplier into a bonus' do
        put admin_score_modifier_path(score_modifier),
            params: { score_modifier: { type: 'Bonus', name: 'hot streak', value: '2' } }

        expect(ScoreModifier.find(score_modifier.id)).to be_a(Bonus)
      end

      context 'when the kind change would break the target kind\'s own rules' do
        let(:score_modifier) { create(:bonus, name: 'legend', value: -5) }

        it 'rejects a bonus becoming a multiplier with a value the multiplier disallows' do
          put admin_score_modifier_path(score_modifier),
              params: { score_modifier: { type: 'Multiplier', name: 'legend', value: '-5' } }

          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'leaves the record as a bonus' do
          put admin_score_modifier_path(score_modifier),
              params: { score_modifier: { type: 'Multiplier', name: 'legend', value: '-5' } }

          expect(ScoreModifier.find(score_modifier.id)).to be_a(Bonus)
        end

        it 'keeps the original value' do
          put admin_score_modifier_path(score_modifier),
              params: { score_modifier: { type: 'Multiplier', name: 'legend', value: '-5' } }

          expect(score_modifier.reload.value).to eq(-5)
        end
      end

      it 'keeps the modifier when the new name is blank' do
        put admin_score_modifier_path(score_modifier),
            params: { score_modifier: { type: 'Multiplier', name: '', value: '2' } }

        expect(score_modifier.reload.name).to eq('hot streak')
      end

      context 'when the new name is not one the platform offers' do
        it 'keeps the modifier' do
          put admin_score_modifier_path(score_modifier),
              params: { score_modifier: { type: 'Multiplier', name: 'Cheater', value: '2' } }

          expect(score_modifier.reload.name).to eq('hot streak')
        end
      end

      context 'when the new kind is not one the platform offers' do
        it 'rejects the update' do
          put admin_score_modifier_path(score_modifier),
              params: { score_modifier: { type: 'User', name: 'hot streak', value: '2' } }

          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'keeps the record as its original kind' do
          put admin_score_modifier_path(score_modifier),
              params: { score_modifier: { type: 'User', name: 'hot streak', value: '2' } }

          expect(ScoreModifier.find(score_modifier.id)).to be_a(Multiplier)
        end
      end
    end

    describe '#destroy' do
      it 'discards the modifier instead of deleting it' do
        score_modifier = create(:multiplier)

        delete admin_score_modifier_path(score_modifier)

        expect(ScoreModifier.find(score_modifier.id).discarded_at).to be_present
      end

      it 'hides the modifier from the kept scope' do
        score_modifier = create(:multiplier)

        delete admin_score_modifier_path(score_modifier)

        expect(ScoreModifier.kept.find_by(id: score_modifier.id)).to be_nil
      end

      it 'returns to the list' do
        delete admin_score_modifier_path(create(:multiplier))

        expect(response).to redirect_to(admin_score_modifiers_path)
      end

      context 'when players hold the modifier' do
        it 'leaves their attachment in place' do
          score_modifier = create(:multiplier)
          player_season_modifier = create(:player_season_modifier, score_modifier:)

          delete admin_score_modifier_path(score_modifier)

          expect(ScoreModifier.find(score_modifier.id).player_season_modifiers)
            .to include(player_season_modifier)
        end

        it 'leaves the player enrolled in the season' do
          score_modifier = create(:multiplier)
          player_season = create(:player_season_modifier, score_modifier:).player_season

          delete admin_score_modifier_path(score_modifier)

          expect(PlayerSeason.find_by(id: player_season.id)).to eq(player_season)
        end
      end
    end

    context 'when the visitor is not an admin' do
      it 'refuses the list' do
        sign_in create(:user)

        get admin_score_modifiers_path

        expect(response).to redirect_to(root_path)
      end
    end
  end

end
