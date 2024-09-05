module Players

  class CostCalculator

    attr_accessor :pricing_rules

    def initialize(pricing_rules: [])
      @pricing_rules = pricing_rules
    end

    def calculate_cost(player:, tournament:)
      score = player.latest_score_before(date: tournament.starting_date)
      cost = 0.00
      pricing_rules.each { |rule| cost = rule.apply(score:, cost:) }
      cost
    end

  end

end
