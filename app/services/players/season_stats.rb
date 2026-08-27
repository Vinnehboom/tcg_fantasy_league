module Players

  class SeasonStats

    def initialize(game:, season_label:)
      @game = game
      @season_label = season_label
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

    attr_reader :game, :season_label

    def scores
      @scores ||= newest_score_per_player
    end

    # Oldest rows first, so `to_h` keeps the newest row of each player.
    # ExternalScore is an append-only time series, so newest wins over
    # taking every row: that keeps import cadence from bending the
    # distribution, and therefore every price.
    def newest_score_per_player
      ExternalScore.joins(:player)
                   .where(players: { game_id: game.id }, season: season_label)
                   .order(:created_at, :id).pluck(:player_id, :score).to_h.values
    end

  end

end
