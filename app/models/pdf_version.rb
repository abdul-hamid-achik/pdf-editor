class PdfVersion < ApplicationRecord
  belongs_to :pdf_document
  belongs_to :user, optional: true

  validates :version_number, presence: true, uniqueness: { scope: :pdf_document_id }

  scope :ordered, -> { order(version_number: :desc) }

  def description
    changes_summary = version_changes.keys.join(", ") if version_changes.present?
    "Version #{version_number}#{changes_summary ? " - #{changes_summary}" : ''}"
  end
end
