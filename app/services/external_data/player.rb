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
      attributes = {
        name:,
        country:
      }
      return attributes if @external_points.blank?

      attributes.merge(external_scores_attributes:)
    end

    def external_scores_attributes
      [
        {
          score: external_points
        }
      ]
    end

  end

end
