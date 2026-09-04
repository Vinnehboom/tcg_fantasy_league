module Admin

  module ScoreModifiers

    class PlayerSeasonModifiersController < Admin::ApplicationController

      # Both actions redirect_back: their consumers are two different pages
      # (this branch's score_modifier show page, and the player page in the
      # stacked PR) and neither is a fixed, knowable target here. :see_other
      # (303) makes Turbo re-fetch the referring page as a GET, so the
      # result - and the flash - actually show up.
      def create
        player_season = chosen_player_season
        score_modifier = ScoreModifier.kept.find(params.dig(:player_season_modifier, :score_modifier_id))
        player_season_modifier = score_modifier.player_season_modifiers.build(player_season:)
        authorize player_season_modifier

        if player_season_modifier.save
          redirect_back fallback_location: admin_score_modifiers_path, status: :see_other, notice: t('.success')
        else
          redirect_back fallback_location: admin_score_modifiers_path, status: :see_other, alert: t('.failed')
        end
      end

      def destroy
        # Not .kept: an attachment to an already-discarded modifier must
        # stay detachable, not 404 - discard doesn't cascade-destroy it.
        score_modifier = ScoreModifier.find(params[:score_modifier_id])
        player_season_modifier = score_modifier.player_season_modifiers.find(params[:id])
        authorize player_season_modifier

        if player_season_modifier.destroy
          redirect_back fallback_location: admin_score_modifiers_path, status: :see_other, notice: t('.success')
        else
          redirect_back fallback_location: admin_score_modifiers_path, status: :see_other, alert: t('.failed')
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
