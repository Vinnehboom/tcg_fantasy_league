FactoryBot.define do
  factory :price do
    player
    external_points { rand(1500).to_s }
    start_time { Faker::Date.forward(days: 3) }
    value { Faker::Number.decimal(l_digits: 2) }
  end
end
