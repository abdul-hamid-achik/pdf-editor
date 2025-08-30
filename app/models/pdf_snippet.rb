class PdfSnippet < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, presence: true

  SNIPPET_TYPES = %w[header footer watermark signature table chart image].freeze

  validates :snippet_type, inclusion: { in: SNIPPET_TYPES }, allow_blank: true

  scope :by_type, ->(type) { where(snippet_type: type) }
  scope :global_snippets, -> { where(global: true) }
  scope :user_snippets, ->(user) { where(user: user) }
  scope :available_for, ->(user) { where(user: [ user, nil ]).or(where(global: true)) }

  def description
    properties&.dig('description') || ''
  end

  def description=(value)
    self.properties ||= {}
    self.properties['description'] = value
  end

  def content
    value = super
    return {} unless value.present?
    
    if value.is_a?(String)
      JSON.parse(value) rescue { 'elements' => [] }
    else
      value
    end
  end
  
  def content=(value)
    super(value.is_a?(Hash) || value.is_a?(Array) ? value.to_json : value)
  end
end
