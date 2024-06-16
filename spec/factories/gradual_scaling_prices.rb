FactoryBot.define do
  factory :gradual_scaling_price do
    type { 'GradualScalingPrice' }
    name { Faker::Name.first_name }
  end
end
