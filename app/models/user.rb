class User < ApplicationRecord
  has_secure_password

  has_many :pdf_templates, dependent: :destroy
  has_many :pdf_snippets, dependent: :destroy
  has_many :pdf_documents, dependent: :destroy
  has_many :pdf_versions, dependent: :nullify

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  before_save { email.downcase! }

  private

  def password_required?
    new_record? || password.present?
  end
end
