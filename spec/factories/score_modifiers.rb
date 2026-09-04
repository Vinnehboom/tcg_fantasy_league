FactoryBot.define do
  factory :score_modifier do
    name { ScoreModifier.names.values.first }
    value { 1 }

    factory :multiplier, class: 'Multiplier' do
      value { 1.5 }
    end

    factory :bonus, class: 'Bonus' do
      value { 5 }
    end

    # The bare base factory can't be persisted: `type` is `null: false` and
    # Rails only auto-populates it for STI subclasses, not the base class
    # itself. Use this trait when a spec needs a persisted modifier but
    # doesn't care which concrete subtype it gets.
    trait :any_subtype do
      initialize_with { ScoreModifier.subclasses.sample.new(name:, value:) }
    end
  end
end
