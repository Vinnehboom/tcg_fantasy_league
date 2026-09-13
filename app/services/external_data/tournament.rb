module ExternalData

  class Tournament < PersistableObject

    attr_accessor :name, :starting_date, :country, :format

    def self.preload(objects)
      return if objects.empty?

      found = ::Tournament.where(game_id: objects.first.game_id, external_id: objects.map(&:external_id))
                          .index_by { |record| [record.external_id, record.game_id] }
      objects.each { |object| object.send(:existing_record=, found[[object.external_id, object.game_id]]) }
    end

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

    def save_associations(*); end

  end

end
