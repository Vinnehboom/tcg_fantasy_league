FactoryBot.define do
  factory :participation do
    draft factory: :salary_draft
    user
  end
end
