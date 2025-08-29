class PdfGenerationJob < ApplicationJob
  queue_as :default

  def perform(pdf_document)
    Rails.logger.info "Starting PDF generation for document #{pdf_document.id}"
    
    # Use our PDF generator service
    generator = Pdf::GeneratorService.new(pdf_document)
    generator.generate
    
    Rails.logger.info "Completed PDF generation for document #{pdf_document.id}"
  rescue StandardError => e
    Rails.logger.error "PDF Generation failed for document #{pdf_document.id}: #{e.message}"
    pdf_document.update!(status: "failed")
    raise e
  end
end
