FactoryBot.define do
  factory :salary_draft do
    tournament
    price_cap { rand(100..1000) }
    roster_size { rand(2..6) }
  end
end
