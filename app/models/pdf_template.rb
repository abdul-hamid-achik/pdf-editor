class PdfTemplate < ApplicationRecord
  belongs_to :user, optional: true
  has_many :pdf_documents, dependent: :nullify

  validates :name, presence: true

  scope :by_category, ->(category) { where(category: category) }
  scope :popular, -> { order(usage_count: :desc) }
  scope :global, -> { where(user_id: nil) }

  def increment_usage!
    increment!(:usage_count)
  end
end
