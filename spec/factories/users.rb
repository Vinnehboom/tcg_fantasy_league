FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    username { Faker::Internet.username }
    password { 'testtest' }

    trait :with_role do
      transient do
        role { 'admin' }
      end

      after(:create) do |user, evaluator|
        user.add_role(evaluator.role.to_sym)
      end
    end
  end
end
