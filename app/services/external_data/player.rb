module ExternalData

  class Player < PersistableObject

    attr_accessor :name, :external_points, :country, :season

    private

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
