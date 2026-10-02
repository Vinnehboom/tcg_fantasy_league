module SalaryDrafts

  class Scorer < ApplicationService

    def initialize(participation:, draft:, strategy_class: Scoring::Strategies::TieredPlacementStrategy)
      super()
      @participation = participation
      @draft = draft
      @strategy_class = strategy_class
    end

    def call
      participation.rosters.each { |roster| score_roster(roster) }
      participation.save!
    end

    private

    attr_reader :participation, :draft, :strategy_class

    def score_roster(roster)
      roster.roster_players.each do |roster_player|
        roster_player.score = points_for(player_id: roster_player.player_id)
      end
      roster.save(context: :scoring)
    end

    def points_for(player_id:)
      results_by_player_id.fetch(player_id, []).sum { |result| strategy.points_for(result:) }
    end

    def results_by_player_id
      @results_by_player_id ||= tournament.results.group_by(&:player_id)
    end

    def strategy
      @strategy ||= strategy_class.for(season: tournament.season)
    end

    def tournament
      draft.tournament
    end

  end

end
