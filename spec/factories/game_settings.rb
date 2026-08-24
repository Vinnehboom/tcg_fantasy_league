FactoryBot.define do
  factory :game_setting do
    season
    settings { { 'scoring' => { 'placement_points' => [10, 6, 3, 1] } } }
  end
end
