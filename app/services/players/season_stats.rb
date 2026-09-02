module Players

  class SeasonStats

    def initialize(game:, season:)
      @game = game
      @season = season
    end

    def average
      return if scores.empty?

      scores.sum / scores.size.to_f
    end

    def median
      return if scores.empty?

      sorted = scores.sort
      middle = sorted.size / 2
      return sorted[middle].to_f if sorted.size.odd?

      (sorted[middle - 1] + sorted[middle]) / 2.0
    end

    private

    attr_reader :game, :season

    def scores
      @scores ||= newest_scores_per_player
    end

    # Oldest rows first, so `to_h` keeps the newest row of each player.
    # ExternalScore is an append-only time series, so newest wins over
    # taking every row: that keeps import cadence from bending the
    # distribution, and therefore every price.
    def newest_scores_per_player
      ExternalScore.joins(player_season: :player)
                   .where(players: { game_id: game.id }, player_seasons: { season_id: season.id })
                   .order(:created_at, :id).pluck('players.id', 'external_scores.score').to_h.values
    end

  end

end
