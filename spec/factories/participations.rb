FactoryBot.define do
  factory :participation do
    draft factory: :salary_draft
    user
    status { 'created' }
    trait :with_roster do
      after(:build) do |participation, _context|
        participation.rosters << build(:roster, :with_players)
      end
    end
  end
end
