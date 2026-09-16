module ExternalData

  class Player < PersistableObject

    attr_accessor :name, :external_points, :country, :season

    def self.preload_associations(objects)
      seasoned = objects.select(&:season)
      return if seasoned.empty?

      index = build_player_season_index(seasoned.select { |object| object.send(:existing_record) })
      seasoned.each { |object| object.send(:player_season_index=, index) }
    end

    def self.build_player_season_index(objects)
      return {} if objects.empty?

      found = find_player_seasons(objects)
      preload_latest_scores(found.values)
      found
    end

    def self.find_player_seasons(objects)
      ::PlayerSeason.where(
        player_id: objects.map { |object| object.send(:existing_record).id },
        season_id: objects.map { |object| object.season.id }.uniq
      ).index_by { |player_season| [player_season.player_id, player_season.season_id] }
    end

    def self.preload_latest_scores(player_seasons)
      return if player_seasons.empty?

      latest = ::ExternalScore.latest_per_player_season(player_seasons.map(&:id)).index_by(&:player_season_id)
      player_seasons.each { |player_season| player_season.latest_score = latest[player_season.id]&.score }
    end

    private_class_method :preload_associations, :build_player_season_index, :find_player_seasons,
                         :preload_latest_scores

    private

    attr_accessor :player_season_index

    def skip?
      !!existing_record&.suppressed?
    end

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
      player_season(record:).record_score!(score: external_points)
    end

    def player_season(record:)
      return record.player_seasons.find_or_create_by!(season:) unless player_season_index

      player_season_index[[record.id, season.id]] ||=
        record.player_seasons.create!(season:).tap { |created| created.latest_score = nil }
    end

  end

end
