module ExternalData

  class PersistableObject

    attr_accessor :game_id, :external_id

    def self.preload(objects)
      return if objects.empty?

      preload_records(objects)
      preload_associations(objects)
    end

    def self.preload_records(objects)
      keyed = objects.reject { |object| object.external_id.nil? }
      return if keyed.empty?

      found = keyed.first.send(:db_class)
                   .where(game_id: keyed.first.game_id, external_id: keyed.map(&:external_id))
                   .index_by { |record| [record.external_id.to_s, record.game_id.to_s] }
      index = keyed.to_h do |object|
        [object.send(:record_key), found[[object.external_id.to_s, object.game_id.to_s]]]
      end
      keyed.each { |object| object.send(:record_index=, index) }
    end

    def self.preload_associations(objects); end

    private_class_method :preload_records, :preload_associations

    def initialize(attributes: {})
      @external_id = attributes[:external_id]
      @game_id = attributes[:game_id]
      post_initialize(attributes:)
    end

    def save!
      return false if skip?

      db_record = existing_record || db_class.new(**lookup_attributes)
      db_record.assign_attributes(instance_attributes)
      db_record.save!
      register(db_record)
      save_associations(record: db_record)
      true
    end

    private

    attr_writer :record_index

    def skip?
      false
    end

    def record_index
      @record_index ||= { record_key => db_class.find_by(**lookup_attributes) }
    end

    def record_key
      lookup_attributes
    end

    def existing_record
      record_index[record_key]
    end

    def register(record)
      record_index[record_key] = record
    end

    def lookup_attributes
      { external_id:, game_id: }
    end

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
