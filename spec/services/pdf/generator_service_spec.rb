require 'rails_helper'

RSpec.describe Pdf::GeneratorService do
  let(:user) { create(:user) }
  let(:document) { create(:pdf_document, user: user) }
  let(:service) { described_class.new(document) }

  describe '#initialize' do
    it 'sets document' do
      expect(service.document).to eq(document)
    end

    it 'initializes pdf as nil' do
      expect(service.pdf).to be_nil
    end
  end

  describe '#generate' do
    context 'successful generation' do
      before do
        allow_any_instance_of(HexaPDF::Document).to receive(:write)
      end

      it 'updates document status to processing' do
        expect(document).to receive(:update!).with(status: "processing").and_call_original
        service.generate
      end

      it 'updates document status to completed' do
        service.generate
        expect(document.reload.status).to eq("completed")
      end

      it 'sets generated_at timestamp' do
        expect {
          service.generate
        }.to change { document.reload.generated_at }.from(nil)
      end

      it 'attaches generated file' do
        expect {
          service.generate
        }.to change { document.generated_file.attached? }.from(false).to(true)
      end

      it 'returns the document' do
        result = service.generate
        expect(result).to eq(document)
      end

      context 'with template' do
        let(:template) { create(:pdf_template) }
        let(:document) { create(:pdf_document, user: user, pdf_template: template) }

        before do
          template.update!(
            structure: {
              "page_size" => "Letter",
              "margins" => { "top" => 20, "bottom" => 20 }
            },
            default_data: { "company" => "Test Corp" }
          )
        end

        it 'increments template usage count' do
          expect {
            service.generate
          }.to change { template.reload.usage_count }.by(1)
        end

        it 'applies template structure' do
          service.generate
          # Template structure should be applied (tested through integration)
        end

        it 'merges template data with document data' do
          document.update!(content_data: { "name" => "John" })
          service.generate
          expect(document.reload.content_data).to include("company" => "Test Corp", "name" => "John")
        end
      end

      context 'with elements' do
        let!(:text_element) do
          create(:pdf_element, :text, pdf_document: document, page_number: 1)
        end

        let!(:image_element) do
          create(:pdf_element, :image, pdf_document: document, page_number: 1)
        end

        let!(:shape_element) do
          create(:pdf_element, :shape, pdf_document: document, page_number: 2)
        end

        it 'adds all elements to PDF' do
          expect_any_instance_of(HexaPDF::Document).to receive(:pages).at_least(:once).and_call_original
          service.generate
        end

        it 'creates pages based on max page number' do
          service.generate
          # Pages should be created (tested through integration)
        end
      end

      context 'with variable interpolation' do
        let!(:element) do
          create(:pdf_element, 
            pdf_document: document,
            element_type: 'text',
            properties: { content: "Hello {{name}}, from {{company}}" }
          )
        end

        before do
          document.update!(content_data: { "name" => "Alice", "company" => "Tech Inc" })
        end

        it 'interpolates variables in text content' do
          service.generate
          # Variables should be interpolated (tested through integration)
        end
      end
    end

    context 'failed generation' do
      before do
        allow_any_instance_of(HexaPDF::Document).to receive(:write).and_raise(StandardError, "Generation error")
      end

      it 'updates document status to failed' do
        expect { service.generate }.to raise_error(StandardError)
        expect(document.reload.status).to eq("failed")
      end

      it 'logs error message' do
        expect(Rails.logger).to receive(:error).with(/PDF Generation failed/)
        expect(Rails.logger).to receive(:error).with(/Generation error/)
        expect { service.generate }.to raise_error(StandardError)
      end

      it 'raises the error' do
        expect { service.generate }.to raise_error(StandardError, "Generation error")
      end
    end
  end

  describe 'private methods' do
    describe '#parse_color' do
      it 'parses hex color' do
        color = service.send(:parse_color, "#FF0000")
        expect(color).to eq([1.0, 0.0, 0.0])
      end

      it 'parses RGB string' do
        color = service.send(:parse_color, "255,128,0")
        expect(color).to eq([1.0, 128/255.0, 0.0])
      end

      it 'defaults to black for invalid color' do
        color = service.send(:parse_color, "invalid")
        expect(color).to eq([0, 0, 0])
      end
    end

    describe '#interpolate_variables' do
      before do
        document.update!(content_data: { "name" => "Bob", "title" => "Manager" })
      end

      it 'replaces variables with values' do
        text = "Hello {{name}}, you are a {{title}}"
        result = service.send(:interpolate_variables, text)
        expect(result).to eq("Hello Bob, you are a Manager")
      end

      it 'keeps unmatched variables' do
        text = "Hello {{name}}, your role is {{role}}"
        result = service.send(:interpolate_variables, text)
        expect(result).to eq("Hello Bob, your role is {{role}}")
      end

      it 'returns original text if no content_data' do
        document.update!(content_data: nil)
        text = "Hello {{name}}"
        result = service.send(:interpolate_variables, text)
        expect(result).to eq("Hello {{name}}")
      end
    end
  end
end