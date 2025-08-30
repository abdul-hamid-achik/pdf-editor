FactoryBot.define do
  factory :pdf_version do
    association :pdf_document
    association :user
    sequence(:version_number) { |n| n }
    version_changes { { updated_elements: [1, 2, 3] } }

    trait :without_user do
      user { nil }
    end

    trait :major_changes do
      version_changes do
        {
          added_pages: [2, 3],
          removed_pages: [],
          updated_elements: [1, 4, 5, 6],
          layout_changes: true
        }
      end
    end

    trait :minor_changes do
      version_changes do
        {
          updated_elements: [1],
          text_edits: true
        }
      end
    end
  end
end