FactoryBot.define do
  factory :setting do
    season
    settings { { 'scoring' => { 'placement_points' => [10, 6, 3, 1] } } }

    # Owned by a Game instead of a Season (a game's app-wide default row).
    # Clears the default `season` association so only the `settingable=`
    # polymorphic writer runs, letting `settingable_type` come through as
    # 'Game' rather than being inferred as 'Season'.
    trait :for_game do
      season { nil }
      settingable { association(:game) }
    end
  end
end
