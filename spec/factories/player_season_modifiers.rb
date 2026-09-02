FactoryBot.define do
  factory :player_season_modifier do
    player_season
    score_modifier factory: %i[multiplier]
  end
end
