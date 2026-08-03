FactoryBot.define do
  factory :external_request do
    game
    kind { :players }
    started_at { Time.current }
    source_url { Faker::Internet.url }

    trait :success do
      status { :success }
      records_processed { rand(1..500) }
      finished_at { Time.current }
      response_body { { 'count' => records_processed } }
    end

    trait :failure do
      status { :failure }
      error { Faker::Lorem.sentence }
      finished_at { Time.current }
    end
  end
end
