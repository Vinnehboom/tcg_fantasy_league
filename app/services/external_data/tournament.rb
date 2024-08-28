module ExternalData

  class Tournament < PersistableObject

    attr_accessor :name, :starting_date, :country, :format

    private

    def db_class
      ::Tournament
    end

    def post_initialize(attributes: {})
      @name = attributes[:name]
      @starting_date = attributes[:starting_date]
      @country = attributes[:country]
      @format = attributes[:format]
    end

    def instance_attributes
      {
        name:,
        country:,
        starting_date:,
        format:
      }
    end

  end

end
