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

    private

    attr_reader :game, :season

    def scores
      @scores ||= latest_score_per_player.sort
    end

    # Oldest rows first, so `to_h` keeps the newest row of each player.
    # Scoped by game_id too, so two games sharing a season label (should
    # that ever happen) can never mix their scores.
    def latest_score_per_player
      ExternalScore.joins(:player)
                   .where(players: { game_id: game.id }, season:)
                   .order(:created_at, :id).pluck(:player_id, :score).to_h.values
    end

  end

end
