module SalaryDrafts

  class Scorer < ApplicationService

    def initialize(participation:, draft:)
      super()
      @participation = participation
      @draft = draft
    end

    def call
      calculate_score(rosters: participation.rosters, draft:)
      participation.save!
    end

    private

    attr_reader :participation, :draft

    def calculate_score(rosters:, draft:)
      tournament_date = draft.tournament.starting_date
      rosters.map(&:roster_players).flatten.each do |roster_player|
        roster_player.score = roster_player.player.score_difference(date: 1.day.from_now, other_date: tournament_date)
        roster_player.roster.save(context: :scoring)
      end
    end

  end

end
