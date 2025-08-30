FactoryBot.define do
  factory :pdf_snippet do
    name { "Snippet #{Faker::Number.unique.number(digits: 4)}" }
    description { Faker::Lorem.sentence }
    snippet_type { PdfSnippet::SNIPPET_TYPES.sample }
    content { { elements: [] } }
    global { false }

    trait :global do
      global { true }
      user { nil }
    end

    trait :with_user do
      association :user
    end

    trait :header do
      snippet_type { "header" }
      content do
        {
          elements: [
            { type: "text", content: "Header Title", position: { x: 50, y: 20 } }
          ]
        }
      end
    end

    trait :footer do
      snippet_type { "footer" }
      content do
        {
          elements: [
            { type: "text", content: "Page [page_number]", position: { x: 250, y: 800 } }
          ]
        }
      end
    end

    trait :watermark do
      snippet_type { "watermark" }
      content do
        {
          elements: [
            { type: "text", content: "CONFIDENTIAL", opacity: 0.3, rotation: 45 }
          ]
        }
      end
    end

    trait :signature do
      snippet_type { "signature" }
      content do
        {
          elements: [
            { type: "signature", position: { x: 400, y: 700 }, dimensions: { width: 150, height: 50 } }
          ]
        }
      end
    end
  end
end