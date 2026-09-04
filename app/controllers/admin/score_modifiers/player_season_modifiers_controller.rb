module Admin

  module ScoreModifiers

    class PlayerSeasonModifiersController < Admin::ApplicationController

      # Headless: this action's only consumer is a form on the player's own
      # page (a separate PR/route), which reloads itself to show the result.
      # There's nothing here for this controller to redirect to on its own.
      def create
        player_season = chosen_player_season
        score_modifier = ScoreModifier.kept.find(params.dig(:player_season_modifier, :score_modifier_id))
        player_season_modifier = score_modifier.player_season_modifiers.build(player_season:)
        authorize player_season_modifier

        if player_season_modifier.save
          head :no_content
        else
          head :unprocessable_entity
        end
      end

      def destroy
        # Not .kept: an attachment to an already-discarded modifier must
        # stay detachable, not 404 - discard doesn't cascade-destroy it.
        score_modifier = ScoreModifier.find(params[:score_modifier_id])
        player_season_modifier = score_modifier.player_season_modifiers.find(params[:id])
        authorize player_season_modifier

        if player_season_modifier.destroy
          head :no_content
        else
          head :unprocessable_entity
        end
      end

      private

      # The attach form lives on the player's own page, one form per
      # player_season row, so it only ever offers a real row - a direct
      # lookup, with no unmatched-pair case to guard against.
      def chosen_player_season
        PlayerSeason.find(params.dig(:player_season_modifier, :player_season_id))
      end

    end

  end

end
