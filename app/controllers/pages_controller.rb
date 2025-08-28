class PagesController < ApplicationController
  def home
    # Could add some stats or recent documents for the home page
    @recent_documents = PdfDocument.order(updated_at: :desc).limit(6)
    @total_documents = PdfDocument.count
    @completed_documents = PdfDocument.where(status: "completed").count
  end
end
