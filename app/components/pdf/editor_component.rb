class Pdf::EditorComponent < ViewComponent::Base
  def initialize(pdf_document:, elements: nil)
    @pdf_document = pdf_document
    @elements = elements || pdf_document.pdf_elements
  end

  private

  attr_reader :pdf_document, :elements

  def editor_id
    "pdf-editor-#{pdf_document.id}"
  end

  def canvas_id
    "pdf-canvas-#{pdf_document.id}"
  end

  def toolbar_id
    "pdf-toolbar-#{pdf_document.id}"
  end

  def properties_panel_id
    "pdf-properties-#{pdf_document.id}"
  end

  def element_types
    [
      { type: 'text', label: 'Text', icon: 'Type' },
      { type: 'image', label: 'Image', icon: 'Image' },
      { type: 'shape', label: 'Shape', icon: 'Square' },
      { type: 'line', label: 'Line', icon: 'Minus' },
      { type: 'table', label: 'Table', icon: 'Table' },
      { type: 'signature', label: 'Signature', icon: 'PenTool' }
    ]
  end
end