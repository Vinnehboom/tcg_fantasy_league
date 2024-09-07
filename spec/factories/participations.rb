FactoryBot.define do
  factory :participation do
    draft factory: :salary_draft
    user
    status { 'created' }
  end
end
