class PdfElement < ApplicationRecord
  belongs_to :pdf_document

  ELEMENT_TYPES = %w[text image shape table chart line signature].freeze

  validates :element_type, inclusion: { in: ELEMENT_TYPES }
  validates :page_number, numericality: { greater_than: 0 }
  validates :z_index, numericality: { greater_than_or_equal_to: 0 }

  scope :by_page, ->(page) { where(page_number: page) }
  scope :ordered, -> { order(:page_number, :z_index) }
  scope :by_type, ->(type) { where(element_type: type) }

  def content
    properties["content"] || {}
  end

  def content=(value)
    self.properties = properties.merge("content" => value)
  end

  def styles
    properties["styles"] || {}
  end

  def styles=(value)
    self.properties = properties.merge("styles" => value)
  end

  def render_properties
    {
      type: element_type,
      position: { x: x_position, y: y_position },
      dimensions: { width: width, height: height },
      **properties.symbolize_keys
    }
  end

  def move_to(x, y)
    update!(x_position: x, y_position: y)
  end

  def resize(width, height)
    update!(width: width, height: height)
  end

  def bring_to_front
    max_z = pdf_document.pdf_elements.by_page(page_number).maximum(:z_index) || 0
    update!(z_index: max_z + 1)
  end

  def send_to_back
    update!(z_index: 0)
    pdf_document.pdf_elements.by_page(page_number).where.not(id: id).each do |element|
      element.increment!(:z_index)
    end
  end
end
