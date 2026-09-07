FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    username { Faker::Internet.username }
    password { 'testtest' }
    country { 'US' }
    date_of_birth { 30.years.ago.to_date }

    trait :adult do
      date_of_birth { 30.years.ago.to_date }
    end

    trait :minor do
      date_of_birth { 10.years.ago.to_date }
    end

    trait :incomplete_profile do
      country { nil }
      date_of_birth { nil }

      to_create { |instance| instance.save!(validate: false) }
    end

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
