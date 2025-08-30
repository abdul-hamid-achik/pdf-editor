FactoryBot.define do
  factory :pdf_template do
    name { "Template #{Faker::Number.unique.number(digits: 4)}" }
    description { Faker::Lorem.sentence }
    category { %w[business education personal legal medical].sample }
    structure { { orientation: "portrait", margins: { top: 20, bottom: 20, left: 20, right: 20 } } }
    usage_count { 0 }

    trait :global do
      user { nil }
    end

    trait :with_user do
      association :user
    end

    trait :popular do
      usage_count { Faker::Number.between(from: 100, to: 1000) }
    end
  end
end