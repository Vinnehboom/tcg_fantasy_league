FactoryBot.define do
  factory :external_score do
    transient do
      player { nil }
    end

    player_season do
      next create(:player_season) unless player

      season = player.game.seasons.first || create(:season, game: player.game)
      player.player_seasons.find_or_create_by!(season:)
    end

    score { rand(1..500) }
  end
end
