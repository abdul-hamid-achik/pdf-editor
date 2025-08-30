FactoryBot.define do
  factory :pdf_document do
    association :user
    title { "Document #{Faker::Number.unique.number(digits: 4)}" }
    status { "draft" }
    metadata { { pages: 1, format: "A4" } }
    content_data { { version: "1.0" } }

    trait :with_template do
      association :pdf_template
    end

    trait :completed do
      status { "completed" }
      generated_at { Time.current }
    end

    trait :processing do
      status { "processing" }
    end

    trait :failed do
      status { "failed" }
    end

    trait :with_elements do
      after(:create) do |document|
        create_list(:pdf_element, 5, pdf_document: document)
      end
    end

    trait :with_versions do
      after(:create) do |document|
        create_list(:pdf_version, 3, pdf_document: document)
      end
    end

    trait :with_generated_file do
      after(:create) do |document|
        document.generated_file.attach(
          io: StringIO.new("Mock PDF Content"),
          filename: "document.pdf",
          content_type: "application/pdf"
        )
      end
    end
  end
end