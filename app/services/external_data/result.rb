module ExternalData

  class Result < PersistableObject

    attr_accessor :player_external_id, :player_name, :player_country, :placement, :tournament

    private

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
      { placement: }
    end

    def lookup_attributes
      { player_id: resolved_player.id, tournament_id: tournament.id }
    end

    def resolved_player
      @resolved_player ||= existing_player || ::Player.create!(
        external_id: player_external_id, game_id: tournament.game_id, name: player_name, country: player_country
      )
    end

    def existing_player
      @existing_player ||= ::Player.unscoped.find_by(external_id: player_external_id, game_id: tournament.game_id)
    end

    def save_associations(*); end

  end

end
