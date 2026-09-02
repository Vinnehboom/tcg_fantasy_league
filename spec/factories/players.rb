FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    country { Faker::Address.country_code }
    sequence :external_id do |n|
      "/players/#{n}"
    end
    game
    after(:build) do |player, _context|
      season = player.game.persisted? ? player.game.seasons.first : nil
      season ||= build(:season, game: player.game)
      player_season = build(:player_season, player:, season:)
      player.player_seasons << player_season
      player_season.external_scores << build(:external_score, player_season:)
    end

    trait :without_scores do
      after(:build) do |player, _context|
        player.player_seasons = []
        player.external_scores = []
      end
    end
  end
end
