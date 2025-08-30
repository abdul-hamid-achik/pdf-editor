FactoryBot.define do
  factory :pdf_element do
    association :pdf_document
    element_type { PdfElement::ELEMENT_TYPES.sample }
    page_number { 1 }
    x_position { Faker::Number.between(from: 0, to: 500) }
    y_position { Faker::Number.between(from: 0, to: 700) }
    width { Faker::Number.between(from: 50, to: 200) }
    height { Faker::Number.between(from: 20, to: 100) }
    z_index { 0 }
    properties { {} }

    trait :text do
      element_type { "text" }
      properties do
        {
          content: Faker::Lorem.paragraph,
          styles: {
            font_size: 12,
            font_family: "Helvetica",
            color: "#000000"
          }
        }
      end
    end

    trait :image do
      element_type { "image" }
      properties do
        {
          content: { url: Faker::Internet.url },
          styles: { opacity: 1.0 }
        }
      end
    end

    trait :shape do
      element_type { "shape" }
      properties do
        {
          content: { type: "rectangle" },
          styles: {
            fill_color: "#FF0000",
            border_color: "#000000",
            border_width: 1
          }
        }
      end
    end

    trait :table do
      element_type { "table" }
      properties do
        {
          content: {
            rows: 3,
            columns: 3,
            data: Array.new(3) { Array.new(3) { Faker::Lorem.word } }
          },
          styles: {
            border: true,
            header_row: true
          }
        }
      end
    end

    trait :signature do
      element_type { "signature" }
      properties do
        {
          content: { signature_data: "base64_encoded_signature" },
          styles: { stroke_width: 2 }
        }
      end
    end
  end
end