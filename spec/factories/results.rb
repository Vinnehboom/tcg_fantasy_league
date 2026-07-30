FactoryBot.define do
  factory :result do
    player
    tournament
    placement { rand(1..128) }
  end
end
