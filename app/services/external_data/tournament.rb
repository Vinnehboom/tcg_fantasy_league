module ExternalData

  class Tournament < PersistableObject

    attr_accessor :name, :starting_date, :country, :format

    def initialize(attrs = {})
      super
      @name = attrs[:name]
      @starting_date = attrs[:starting_date]
      @country = attrs[:country]
      @format = attrs[:format]
    end

    def db_class
      ::Tournament
    end

  end

end
