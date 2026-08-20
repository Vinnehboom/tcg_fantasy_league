FactoryBot.define do
  factory :season do
    game
    label { '2026' }
    start_date { Date.new(2025, 9, 1) }
    end_date { Date.new(2026, 8, 31) }
  end
end
