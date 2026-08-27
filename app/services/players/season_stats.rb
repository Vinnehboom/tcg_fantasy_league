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

      middle = scores.size / 2
      return scores[middle].to_f if scores.size.odd?

      (scores[middle - 1] + scores[middle]) / 2.0
    end

    private

    attr_reader :game, :season_label

    def scores
      @scores ||= newest_scores.sort
    end

    # Oldest rows first, so `to_h` keeps the newest row of each player.
    # ExternalScore is an append-only time series: taking every row would
    # let import cadence (how often a player gets rescored) bend the
    # distribution, and therefore every price.
    def newest_scores
      ExternalScore.joins(:player)
                   .where(players: { game_id: game.id }, season: season_label)
                   .order(:created_at, :id).pluck(:player_id, :score).to_h.values
    end

  end

end
