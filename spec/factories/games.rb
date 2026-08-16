FactoryBot.define do
  factory :game do
    sequence(:id) { |n| "GAME#{n}" } # rubocop:disable FactoryBot/IdSequence
    name { Faker::Game.title }
    base_uri { Faker::Internet.url }
  end
end
