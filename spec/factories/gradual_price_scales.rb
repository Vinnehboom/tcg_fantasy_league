FactoryBot.define do
  factory :gradual_price_scale do
    gradual_scaling_price
    point_coefficient { Faker::Number.decimal(l_digits: 2) }
    minimum_price { Faker::Number.decimal(l_digits: 1) }
    maximum_price { Faker::Number.decimal(l_digits: 2) }
  end
end
