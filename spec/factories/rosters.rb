FactoryBot.define do
  factory :roster do
    participation
    trait :with_players do
      after(:build) do |roster, _context|
        roster.players << build(:player)
      end
    end
  end
end
