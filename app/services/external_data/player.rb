module ExternalData

  class Player < PersistableObject

    attr_accessor :name, :external_points, :country, :season

    def self.preload(objects)
      return if objects.empty?

      found = ::Player.where(game_id: objects.first.game_id, external_id: objects.map(&:external_id))
                      .index_by { |record| [record.external_id, record.game_id] }
      objects.each { |object| object.send(:existing_record=, found[[object.external_id, object.game_id]]) }
    end

    private

    def skip?
      !!existing_record&.suppressed?
    end

    def db_class
      ::Player
    end

    def post_initialize(attributes: {})
      @name = attributes[:name]
      @country = attributes[:country]
      @external_points = attributes[:external_points]
      @season = attributes[:season]
    end

    def instance_attributes
      {
        name:,
        country:
      }
    end

    def save_associations(record:)
      record.record_score!(score: external_points, season:)
    end

  end

end
