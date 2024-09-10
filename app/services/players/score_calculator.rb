module Players

  class ScoreCalculator

    attr_accessor :pricing_rules

    def initialize(pricing_rules: [])
      @pricing_rules = pricing_rules
    end

    def calculate_score(cost:)
      score = 0
      pricing_rules.reverse.each { |rule| score = rule.unapply(score:, cost:) }
      score
    end

  end

end
