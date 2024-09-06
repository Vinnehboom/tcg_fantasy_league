module ExternalData

  class PersistableObject

    attr_accessor :game_id, :external_id

    def initialize(attributes: {})
      @external_id = attributes[:external_id]
      @game_id = attributes[:game_id]
      post_initialize(attributes:)
    end

    def save!
      db_record = db_class.find_or_initialize_by(external_id:, game_id:)
      db_record.assign_attributes(instance_attributes)
      db_record.save!
      save_associations(record: db_record)
    end

    private

    def instance_attributes
      raise '#instance_attributes not implemented'
    end

    def post_initialize(*)
      raise '#post_initialize not implemented'
    end

    def save_associations(*)
      raise '#save_associations not implemented'
    end

  end

end
