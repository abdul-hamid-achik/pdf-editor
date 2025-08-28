class PdfDocument < ApplicationRecord
  belongs_to :user
  belongs_to :pdf_template, optional: true
  has_many :pdf_elements, dependent: :destroy
  has_many :pdf_versions, dependent: :destroy
  has_one_attached :generated_file

  STATUSES = %w[draft processing completed failed].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :drafts, -> { where(status: "draft") }
  scope :completed, -> { where(status: "completed") }
  scope :processing, -> { where(status: "processing") }
  scope :failed, -> { where(status: "failed") }

  before_create :set_default_title

  def generate_pdf!
    update!(status: "processing")
    PdfGenerationJob.perform_later(self)
  end

  def add_element(element_params)
    pdf_elements.create!(element_params)
  end

  def duplicate
    new_doc = self.class.new(
      attributes.except("id", "created_at", "updated_at", "generated_at")
    )

    pdf_elements.each do |element|
      new_doc.pdf_elements.build(
        element.attributes.except("id", "pdf_document_id", "created_at", "updated_at")
      )
    end

    new_doc
  end

  def create_version!(user: nil, changes: {})
    version_number = pdf_versions.maximum(:version_number).to_i + 1
    pdf_versions.create!(
      version_number: version_number,
      version_changes: changes,
      user: user
    )
  end

  private

  def set_default_title
    self.title ||= "Untitled Document #{Time.current.strftime('%Y-%m-%d')}"
  end
end
