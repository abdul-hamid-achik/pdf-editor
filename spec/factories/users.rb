FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }

    trait :with_documents do
      after(:create) do |user|
        create_list(:pdf_document, 3, user: user)
      end
    end

    trait :with_templates do
      after(:create) do |user|
        create_list(:pdf_template, 2, user: user)
      end
    end

    trait :with_snippets do
      after(:create) do |user|
        create_list(:pdf_snippet, 3, user: user)
      end
    end
  end
end