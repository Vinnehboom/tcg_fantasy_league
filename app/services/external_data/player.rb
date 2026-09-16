module ExternalData

  class Player < PersistableObject

    attr_accessor :name, :external_points, :country, :season

    def self.preload(objects)
      return if objects.empty?

      preload_records(objects)
      preload_player_seasons(objects)
    end

    def self.preload_records(objects)
      found = ::Player.where(game_id: objects.first.game_id, external_id: objects.map(&:external_id))
                      .index_by { |record| [record.external_id, record.game_id] }
      objects.each { |object| object.send(:existing_record=, found[[object.external_id, object.game_id]]) }
    end

    def self.preload_player_seasons(objects)
      seasoned = objects.select(&:season)
      seasoned.each { |object| object.send(:player_season=, nil) }

      known = seasoned.select { |object| object.send(:existing_record) }
      return if known.empty?

      found = find_player_seasons(known)
      preload_latest_scores(found.values)
      known.each { |object| object.send(:player_season=, found[player_season_key(object)]) }
    end

    def self.find_player_seasons(objects)
      ::PlayerSeason.where(
        player_id: objects.map { |object| object.send(:existing_record).id },
        season_id: objects.map { |object| object.season.id }.uniq
      ).index_by { |player_season| [player_season.player_id, player_season.season_id] }
    end

    def self.player_season_key(object)
      [object.send(:existing_record).id, object.season.id]
    end

    def self.preload_latest_scores(player_seasons)
      return if player_seasons.empty?

      latest = ::ExternalScore.latest_per_player_season(player_seasons.map(&:id)).index_by(&:player_season_id)
      player_seasons.each { |player_season| player_season.latest_score = latest[player_season.id]&.score }
    end

    private_class_method :preload_records, :preload_player_seasons, :preload_latest_scores,
                         :find_player_seasons, :player_season_key

    private

    attr_writer :player_season

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
      return record.player_seasons.find_or_create_by!(season:) unless defined?(@player_season)

      @player_season ||= record.player_seasons.create!(season:).tap { |created| created.latest_score = nil }
    end

  end

end
