module SalaryDrafts

  class Scorer

    def score(participation:, draft:)
      calculate_score(rosters: participation.rosters, draft:)
      participation.save!
    end

    private

    def calculate_score(rosters:, draft:)
      score = 0
      tournament_date = draft.tournament.starting_date
      rosters.map(&:roster_players).flatten.each do |roster_player|
        roster_player.score = roster_player.player.score_difference(date: 1.day.from_now, other_date: tournament_date)
      end
      score
    end

  end

end
