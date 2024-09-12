FactoryBot.define do
  factory :game do
    id { "#{Faker::Game.title} #{rand(10)}" }
    name { Faker::Game.title }
    base_uri { Faker::Internet.url }
  end
end
