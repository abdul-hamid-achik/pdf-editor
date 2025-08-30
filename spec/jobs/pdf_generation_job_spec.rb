require 'rails_helper'

RSpec.describe PdfGenerationJob, type: :job do
  let(:user) { create(:user) }
  let(:pdf_document) { create(:pdf_document, user: user) }

  describe '#perform' do
    let(:generator_service) { instance_double(Pdf::GeneratorService) }

    before do
      allow(Pdf::GeneratorService).to receive(:new).with(pdf_document).and_return(generator_service)
    end

    context 'successful generation' do
      before do
        allow(generator_service).to receive(:generate).and_return(pdf_document)
      end

      it 'logs start message' do
        expect(Rails.logger).to receive(:info).with("Starting PDF generation for document #{pdf_document.id}")
        described_class.new.perform(pdf_document)
      end

      it 'calls generator service' do
        expect(generator_service).to receive(:generate)
        described_class.new.perform(pdf_document)
      end

      it 'logs completion message' do
        expect(Rails.logger).to receive(:info).with("Completed PDF generation for document #{pdf_document.id}")
        described_class.new.perform(pdf_document)
      end
    end

    context 'failed generation' do
      let(:error) { StandardError.new("Generation failed") }

      before do
        allow(generator_service).to receive(:generate).and_raise(error)
      end

      it 'logs error message' do
        expect(Rails.logger).to receive(:error).with("PDF Generation failed for document #{pdf_document.id}: Generation failed")
        expect { described_class.new.perform(pdf_document) }.to raise_error(StandardError)
      end

      it 'updates document status to failed' do
        expect { described_class.new.perform(pdf_document) }.to raise_error(StandardError)
        expect(pdf_document.reload.status).to eq("failed")
      end

      it 're-raises the error' do
        expect { described_class.new.perform(pdf_document) }.to raise_error(StandardError, "Generation failed")
      end
    end
  end

  describe 'queue' do
    it 'uses default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end

  describe 'ActiveJob integration' do
    it 'can be enqueued' do
      expect {
        described_class.perform_later(pdf_document)
      }.to have_enqueued_job(described_class).with(pdf_document)
    end

    it 'can be performed immediately' do
      generator_service = instance_double(Pdf::GeneratorService)
      allow(Pdf::GeneratorService).to receive(:new).and_return(generator_service)
      allow(generator_service).to receive(:generate)

      expect {
        described_class.perform_now(pdf_document)
      }.not_to raise_error
    end
  end
end