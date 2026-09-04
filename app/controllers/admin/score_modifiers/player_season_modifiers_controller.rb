module Admin

  module ScoreModifiers

    class PlayerSeasonModifiersController < Admin::ApplicationController

      def create
        player_season = chosen_player_season
        score_modifier = ScoreModifier.kept.find(params.dig(:player_season_modifier, :score_modifier_id))
        player_season_modifier = score_modifier.player_season_modifiers.build(player_season:)
        authorize player_season_modifier

        if player_season_modifier.save
          render json: { id: player_season_modifier.id }, status: :ok
        else
          render json: { error: t('.failed') }, status: :unprocessable_entity
        end
      end

      def destroy
        # Not .kept: an attachment to an already-discarded modifier must
        # stay detachable - discard doesn't cascade-destroy it.
        player_season_modifier = PlayerSeasonModifier.find(params[:id])
        authorize player_season_modifier

        if player_season_modifier.destroy
          render json: { id: player_season_modifier.id }, status: :ok
        else
          render json: { error: t('.failed') }, status: :unprocessable_entity
        end
      end

      private

      def chosen_player_season
        PlayerSeason.find(params.dig(:player_season_modifier, :player_season_id))
      end

    end

  end

end
