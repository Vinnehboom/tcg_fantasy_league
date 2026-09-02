FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    country { Faker::Address.country_code }
    sequence :external_id do |n|
      "/players/#{n}"
    end
    game

    transient do
      with_score { true }
    end

    after(:build) do |player, evaluator|
      season = player.game.persisted? ? player.game.seasons.first : nil
      season ||= build(:season, game: player.game) if evaluator.with_score
      next unless season

      player_season = build(:player_season, player:, season:)
      player.player_seasons << player_season
      player_season.external_scores << build(:external_score, player_season:) if evaluator.with_score
    end

    # A player still has a player_season - real domain state, e.g. a
    # registered player who hasn't been scored yet - just no score in it -
    # so :without_scores keeps one when the game already has a season to
    # attach it to, and only skips it when there's none to reuse (it never
    # invents one, to avoid colliding with a season the spec builds itself).
    trait :without_scores do
      with_score { false }
    end
  end
end
