module ExternalData

  class Result < PersistableObject

    attr_accessor :player_external_id, :player_name, :player_country, :placement, :tournament

    def self.preload_records(objects)
      tournament = objects.first.tournament
      return if tournament.nil?

      players = find_players(objects, tournament)
      index = find_results(players, tournament)
      objects.each do |object|
        object.send(:player_index=, players)
        object.send(:record_index=, index)
      end
    end

    def self.find_players(objects, tournament)
      ::Player.where(game_id: tournament.game_id, external_id: objects.map(&:player_external_id))
              .index_by { |record| record.external_id.to_s }
    end

    def self.find_results(players, tournament)
      return {} if players.empty?

      ::Result.where(tournament_id: tournament.id, player_id: players.values.map(&:id))
              .index_by { |record| { player_id: record.player_id, tournament_id: record.tournament_id } }
    end

    private_class_method :preload_records, :find_players, :find_results

    private

    attr_writer :player_index

    def skip?
      !!existing_player&.suppressed?
    end

    def db_class
      ::Result
    end

    def post_initialize(attributes: {})
      @player_external_id = attributes[:player_external_id]
      @player_name = attributes[:player_name]
      @player_country = attributes[:player_country]
      @placement = attributes[:placement]
    end

    def instance_attributes
      { placement:, player: resolved_player, tournament: }
    end

    def lookup_attributes
      { player_id: resolved_player.id, tournament_id: tournament.id }
    end

    def player_key
      player_external_id.to_s
    end

    def player_index
      @player_index ||= {
        player_key => ::Player.find_by(external_id: player_external_id, game_id: tournament.game_id)
      }
    end

    def existing_player
      player_index[player_key]
    end

    def resolved_player
      player_index[player_key] ||= ::Player.create!(
        external_id: player_external_id, game_id: tournament.game_id, name: player_name, country: player_country
      )
    end

    def save_associations(*); end

  end

end
