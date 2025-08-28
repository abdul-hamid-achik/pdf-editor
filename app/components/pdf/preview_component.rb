class Pdf::PreviewComponent < ViewComponent::Base
  def initialize(pdf_document:, preview_data: nil)
    @pdf_document = pdf_document
    @preview_data = preview_data
  end

  private

  attr_reader :pdf_document, :preview_data

  def preview_id
    "pdf-preview-#{pdf_document.id}"
  end

  def has_preview?
    preview_data.present? && preview_data[:pages].present?
  end

  def pages
    return [] unless has_preview?
    preview_data[:pages]
  end

  def total_pages
    pages.length
  end

  def document_info
    return {} unless has_preview?
    preview_data[:document_info] || {}
  end

  def page_dimensions
    return { width: 612, height: 792 } unless has_preview?
    document_info.slice(:width, :height).presence || { width: 612, height: 792 }
  end

  def zoom_levels
    [
      { value: 0.25, label: '25%' },
      { value: 0.5, label: '50%' },
      { value: 0.75, label: '75%' },
      { value: 1, label: '100%' },
      { value: 1.25, label: '125%' },
      { value: 1.5, label: '150%' },
      { value: 2, label: '200%' },
      { value: 'fit-width', label: 'Fit Width' },
      { value: 'fit-page', label: 'Fit Page' }
    ]
  end
end