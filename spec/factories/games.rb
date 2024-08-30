FactoryBot.define do
  factory :game do
    id { Faker::Game.title }
    name { Faker::Game.title }
    base_uri { Faker::Internet.url }
  end
end
