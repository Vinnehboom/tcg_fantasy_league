module ExternalData

  class Interface

    def initialize(game)
      @game = game
      @adapter = select_adapter
      super()
    end

    def players
      players = @adapter.players
      players.each { |player| player.game_id = @game.id }
      players
    end

    def update_players
      save_objects(players)
    end

    def upcoming_tournaments
      tournaments = @adapter.upcoming_tournaments
      tournaments.each { |tournament| tournament.game_id = @game.id }
      tournaments
    end

    def update_upcoming_tournaments
      save_objects(upcoming_tournaments)
    end

    private

    def save_objects(objects)
      ActiveRecord::Base.transaction do
        objects.each(&:save)
      end
    end

    def select_adapter
      case @game.name
      when 'PTCG'
        Pokemon::Tcg::Adapter
      else
        OfflineAdapter
      end
    end

  end

end
