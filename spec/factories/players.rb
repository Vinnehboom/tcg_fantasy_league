FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    country { Faker::Address.country_code }
    sequence :external_id do |n|
      "/players/#{n}"
    end
    external_points { rand(1500).to_s }
    game
  end
end
