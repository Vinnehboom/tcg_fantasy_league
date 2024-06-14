module ExternalData

  class Player < PersistableObject

    attr_accessor :name, :external_points, :country

    def initialize(attrs = {})
      super
      @name = attrs[:name]
      @external_points = attrs[:external_points]
      @country = attrs[:country]
    end

    def db_class
      ::Player
    end

  end

end
