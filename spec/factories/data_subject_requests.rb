FactoryBot.define do
  factory :data_subject_request do
    player
    request_type { :erase_or_object }
    contact_email { Faker::Internet.email }

    trait :with_identity_proof_only do
      contact_email { nil }
      identity_proof { Faker::Lorem.paragraph }
    end

    trait :actioned do
      status { :actioned }
      actioned_at { Time.current }
    end
  end
end
