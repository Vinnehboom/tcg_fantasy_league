require 'rails_helper'

module Admin

  RSpec.describe 'ScoreModifiers::PlayerSeasonModifiers' do
    let(:admin) { create(:user, :with_role, role: :admin) }
    let(:score_modifier) { create(:multiplier) }
    let(:player_season) { create(:player_season) }

    before do
      sign_in admin
    end

    describe '#create' do
      let(:params) do
        { player_season_modifier: { player_season_id: player_season.id, score_modifier_id: score_modifier.id } }
      end

      it 'gives the modifier to the player for that season' do
        post(admin_player_season_modifiers_path, params:)

        expect(score_modifier.reload.player_seasons).to include(player_season)
      end

      it 'responds with no content' do
        post(admin_player_season_modifiers_path, params:)

        expect(response).to have_http_status(:no_content)
      end

      context 'when the player already has this modifier for the season' do
        before { create(:player_season_modifier, player_season:, score_modifier:) }

        it 'gives the player nothing more' do
          expect do
            post(admin_player_season_modifiers_path, params:)
          end.not_to change(PlayerSeasonModifier, :count)
        end

        it 'responds unprocessable' do
          post(admin_player_season_modifiers_path, params:)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'when the score_modifier has since been discarded' do
        before { score_modifier.discard }

        it 'refuses to attach it' do
          post(admin_player_season_modifiers_path, params:)

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the player_season does not exist' do
        let(:params) do
          { player_season_modifier: { player_season_id: 0, score_modifier_id: score_modifier.id } }
        end

        it 'returns 404' do
          post(admin_player_season_modifiers_path, params:)

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the score_modifier does not exist' do
        let(:params) do
          { player_season_modifier: { player_season_id: player_season.id, score_modifier_id: 0 } }
        end

        it 'returns 404' do
          post(admin_player_season_modifiers_path, params:)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    describe '#destroy' do
      let(:player_season_modifier) { create(:player_season_modifier, player_season:, score_modifier:) }

      it 'takes the modifier away from the player for that season' do
        delete admin_score_modifier_player_season_modifier_path(score_modifier, player_season_modifier)

        expect(score_modifier.reload.player_seasons).not_to include(player_season)
      end

      it 'responds with no content' do
        delete admin_score_modifier_player_season_modifier_path(score_modifier, player_season_modifier)

        expect(response).to have_http_status(:no_content)
      end

      it 'leaves the player and the season in place' do
        delete admin_score_modifier_player_season_modifier_path(score_modifier, player_season_modifier)

        expect(PlayerSeason.find_by(id: player_season.id)).to eq(player_season)
      end

      context 'when the modifier has since been discarded' do
        before { score_modifier.discard }

        it 'still takes it away from the player for that season' do
          delete admin_score_modifier_player_season_modifier_path(score_modifier, player_season_modifier)

          expect(score_modifier.reload.player_seasons).not_to include(player_season)
        end

        it 'still responds with no content' do
          delete admin_score_modifier_player_season_modifier_path(score_modifier, player_season_modifier)

          expect(response).to have_http_status(:no_content)
        end
      end
    end

    context 'when the visitor is not an admin' do
      it 'refuses to attach a modifier' do
        sign_in create(:user)
        params = {
          player_season_modifier: { player_season_id: player_season.id, score_modifier_id: score_modifier.id }
        }

        post(admin_player_season_modifiers_path, params:)

        expect(response).to redirect_to(root_path)
      end
    end
  end

end
