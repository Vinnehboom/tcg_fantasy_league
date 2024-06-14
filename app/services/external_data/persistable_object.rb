module ExternalData

  class PersistableObject

    attr_accessor :game_id, :external_id

    def initialize(attrs)
      @external_id = attrs[:external_id]
      @game_id = attrs[:game_id]
    end

    def save
      db_record = db_class.find_or_initialize_by(external_id:, game_id:)
      db_record.assign_attributes(instance_values)
      db_record.save!
    end

  end

end
