module ExternalData

  class Result < PersistableObject

    attr_accessor :player_external_id, :player_name, :player_country, :placement, :tournament

    private

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
      { placement: }
    end

    def lookup_attributes
      { player_id: resolved_player.id, tournament_id: tournament.id }
    end

    def resolved_player
      ::Player.find_or_create_by!(external_id: player_external_id, game_id: tournament.game_id) do |player|
        player.name = player_name
        player.country = player_country
      end
    end

    def save_associations(*); end

  end

end
