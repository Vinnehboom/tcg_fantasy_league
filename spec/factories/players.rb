FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    country { Faker::Address.country_code }
    sequence :external_id do |n|
      "/players/#{n}"
    end
    game
    after(:build) do |player, _context|
      player.external_scores << build(:external_score, player:)
    end
  end
end
