FactoryBot.define do
  factory :tournament do
    name { Faker::Game.title }
    sequence :external_id do |n|
      "/tournaments/#{n}"
    end
    country { Faker::Address.country_code }
    game
    format { Tournament.formats.keys.sample }
    starting_date { rand(1..30).days.from_now }
  end
end
