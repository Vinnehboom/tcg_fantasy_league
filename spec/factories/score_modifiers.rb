FactoryBot.define do
  factory :score_modifier do
    sequence(:name) { |n| "Modifier #{n}" }
    value { 1 }

    factory :multiplier, class: 'Multiplier' do
      value { 1.5 }
    end

    factory :bonus, class: 'Bonus' do
      value { 5 }
    end
  end
end
