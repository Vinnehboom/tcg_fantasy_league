module ExternalData

  class Interface

    def initialize(game:, adapter: OfflineAdapter.new)
      @game = game
      @adapter = adapter
    end

    def players
      players = adapter.players
      players.each { |player| player.game_id = game.id }
      players
    end

    def update_players
      save_objects(objects: players)
    end

    def upcoming_tournaments
      tournaments = adapter.upcoming_tournaments
      tournaments.each { |tournament| tournament.game_id = game.id }
      tournaments
    end

    def update_upcoming_tournaments
      save_objects(objects: upcoming_tournaments)
    end

    def results(tournament:)
      results = adapter.results(tournament:)
      results.each { |result| result.tournament = tournament }
      results
    end

    def update_results(tournament:)
      fetched_results = results(tournament:)
      processed = save_objects(objects: fetched_results)
      tournament.update!(field_size: fetched_results.count) if fetched_results.any?
      processed
    end

    private

    attr_reader :game, :adapter

    def save_objects(objects:)
      errors = []
      count = objects.count
      processed = 0
      objects.each do |object|
        processed += 1 if object.save!
      rescue ActiveRecord::RecordInvalid => e
        errors << [object, e.message]
      end
      Rails.logger.debug { "invalid objects: #{errors} \n" }
      Rails.logger.debug { "#{processed} out of #{count} processed" }
      processed
    end

  end

end
