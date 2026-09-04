FactoryBot.define do
  factory :setting do
    season
    settings { { 'scoring' => { 'placement_points' => [10, 6, 3, 1] } } }

    # A Setting can be owned by a Game (global default) or a Season (more
    # specific, overrides the game's default for that season only). This
    # trait builds the game-owned, global one — clears the default `season`
    # association so only the `settingable=` polymorphic writer runs,
    # letting `settingable_type` come through as 'Game' rather than being
    # inferred as 'Season'.
    trait :for_game do
      season { nil }
      settingable { association(:game) }
    end
  end
end
