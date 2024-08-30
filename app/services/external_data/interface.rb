module ExternalData

  class Interface

    def initialize(game:)
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
      save_objects(objects: players)
    end

    def upcoming_tournaments
      tournaments = @adapter.upcoming_tournaments
      tournaments.each { |tournament| tournament.game_id = @game.id }
      tournaments
    end

    def update_upcoming_tournaments
      save_objects(objects: upcoming_tournaments)
    end

    private

    def save_objects(objects:)
      @errors = []
      count = objects.count
      @processed = 0
      objects.each do |object|
        @processed += 1 if object.save!
      rescue ActiveRecord::RecordInvalid => e
        @errors << [object, e.message]
      end
      Rails.logger.debug { "invalid objects: #{@errors} \n" }
      Rails.logger.debug { "#{@processed} out of #{count} processed" }
    end

    def select_adapter
      case @game.id
      when 'PTCG'
        Pokemon::Tcg::Adapter
      else
        OfflineAdapter
      end
    end

  end

end
