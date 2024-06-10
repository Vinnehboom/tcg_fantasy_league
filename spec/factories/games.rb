FactoryBot.define do
  factory :game do
    name { Faker::Game.title }
    base_uri { Faker::Internet.url }
  end
end
