FactoryBot.define do
  factory :external_score do
    player
    score { rand(1..500) }
  end
end
