module Admin

  module PlayersHelper

    # player_season_modifiers has a uniqueness constraint on
    # [player_season_id, score_modifier_id] - offering an already-attached
    # modifier here would just fail on submit.
    def available_score_modifiers(player_season:, kept_score_modifiers: ScoreModifier.kept.order(:name))
      attached_ids = player_season.player_season_modifiers.map(&:score_modifier_id)
      kept_score_modifiers.reject { |score_modifier| attached_ids.include?(score_modifier.id) }
    end

  end

end
