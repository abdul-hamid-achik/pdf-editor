class Pdf::DocumentListComponent < ViewComponent::Base
  def initialize(documents:, current_user: nil)
    @documents = documents
    @current_user = current_user
  end

  private

  attr_reader :documents, :current_user

  def document_card_classes(document)
    base_classes = "bg-white rounded-lg border border-gray-200 hover:border-gray-300 hover:shadow-md transition-all duration-200 cursor-pointer"
    
    case document.status
    when 'completed'
      "#{base_classes} border-l-4 border-l-green-500"
    when 'processing'
      "#{base_classes} border-l-4 border-l-blue-500"
    when 'failed'
      "#{base_classes} border-l-4 border-l-red-500"
    else
      "#{base_classes} border-l-4 border-l-gray-300"
    end
  end

  def status_badge_classes(status)
    case status
    when 'completed'
      'bg-green-100 text-green-800'
    when 'processing'
      'bg-blue-100 text-blue-800'
    when 'failed'
      'bg-red-100 text-red-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def status_icon(status)
    case status
    when 'completed'
      '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
      </svg>'.html_safe
    when 'processing'
      '<svg class="w-4 h-4 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
      </svg>'.html_safe
    when 'failed'
      '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
      </svg>'.html_safe
    else
      '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
      </svg>'.html_safe
    end
  end

  def truncate_description(description, limit = 100)
    return '' unless description
    description.length > limit ? "#{description[0, limit]}..." : description
  end

  def element_count(document)
    document.pdf_elements.count
  end

  def file_size(document)
    return 'N/A' unless document.generated_file.attached?
    
    size = document.generated_file.byte_size
    if size < 1024
      "#{size} B"
    elsif size < 1024 * 1024
      "#{(size / 1024.0).round(1)} KB"
    else
      "#{(size / (1024.0 * 1024.0)).round(1)} MB"
    end
  end
end