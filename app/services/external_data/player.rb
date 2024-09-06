module ExternalData

  class Player < PersistableObject

    attr_accessor :name, :external_points, :country

    private

    def db_class
      ::Player
    end

    def post_initialize(attributes: {})
      @name = attributes[:name]
      @country = attributes[:country]
      @external_points = attributes[:external_points]
    end

    def instance_attributes
      {
        name:,
        country:
      }
    end

    def save_associations(record:)
      record.external_scores.create!(score: external_points)
    end

  end

end
