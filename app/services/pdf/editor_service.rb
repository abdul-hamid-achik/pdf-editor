module Pdf
  class EditorService
    attr_reader :document, :pdf
    
    def initialize(document)
      @document = document
      load_existing_pdf if document.generated_file.attached?
    end
    
    def load_existing_pdf
      @pdf = HexaPDF::Document.open(
        StringIO.new(@document.generated_file.download),
        decryption_opts: { password: '' }
      )
    rescue StandardError => e
      Rails.logger.error "Failed to load PDF: #{e.message}"
      @pdf = HexaPDF::Document.new
    end
    
    def add_text(page_number, text, options = {})
      ensure_page_exists(page_number)
      
      element = @document.pdf_elements.create!(
        element_type: 'text',
        page_number: page_number,
        x_position: options[:x] || 50,
        y_position: options[:y] || 50,
        properties: {
          content: text,
          font_family: options[:font] || 'Helvetica',
          font_size: options[:size] || 12,
          color: options[:color] || '#000000'
        }
      )
      
      regenerate_pdf
      element
    end
    
    def add_image(page_number, image_source, options = {})
      ensure_page_exists(page_number)
      
      properties = if image_source.is_a?(String) && image_source.start_with?('http')
        { image_url: image_source }
      else
        { image_data: Base64.encode64(image_source) }
      end
      
      element = @document.pdf_elements.create!(
        element_type: 'image',
        page_number: page_number,
        x_position: options[:x] || 50,
        y_position: options[:y] || 50,
        width: options[:width] || 100,
        height: options[:height] || 100,
        properties: properties
      )
      
      regenerate_pdf
      element
    end
    
    def add_shape(page_number, shape_type, options = {})
      ensure_page_exists(page_number)
      
      element = @document.pdf_elements.create!(
        element_type: 'shape',
        page_number: page_number,
        x_position: options[:x] || 50,
        y_position: options[:y] || 50,
        width: options[:width] || 100,
        height: options[:height] || 100,
        properties: {
          shape_type: shape_type,
          fill_color: options[:fill_color],
          stroke_color: options[:stroke_color] || '#000000',
          line_width: options[:line_width] || 1
        }
      )
      
      regenerate_pdf
      element
    end
    
    def update_element(element_id, updates = {})
      element = @document.pdf_elements.find(element_id)
      
      if updates[:position]
        element.x_position = updates[:position][:x] if updates[:position][:x]
        element.y_position = updates[:position][:y] if updates[:position][:y]
      end
      
      if updates[:dimensions]
        element.width = updates[:dimensions][:width] if updates[:dimensions][:width]
        element.height = updates[:dimensions][:height] if updates[:dimensions][:height]
      end
      
      if updates[:properties]
        element.properties = element.properties.merge(updates[:properties])
      end
      
      element.save!
      regenerate_pdf
      element
    end
    
    def delete_element(element_id)
      element = @document.pdf_elements.find(element_id)
      element.destroy!
      regenerate_pdf
    end
    
    def add_page(options = {})
      max_page = @document.pdf_elements.maximum(:page_number) || 0
      new_page_number = max_page + 1
      
      # Create a placeholder element to ensure the page exists
      @document.pdf_elements.create!(
        element_type: 'text',
        page_number: new_page_number,
        x_position: -1000,
        y_position: -1000,
        properties: { content: '', hidden: true }
      )
      
      regenerate_pdf
      new_page_number
    end
    
    def delete_page(page_number)
      # Delete all elements on this page
      @document.pdf_elements.by_page(page_number).destroy_all
      
      # Renumber subsequent pages
      @document.pdf_elements.where('page_number > ?', page_number).each do |element|
        element.update!(page_number: element.page_number - 1)
      end
      
      regenerate_pdf
    end
    
    def reorder_pages(new_order)
      # new_order is an array of page numbers in the desired order
      # e.g., [3, 1, 2] means page 3 becomes page 1, page 1 becomes page 2, etc.
      
      temp_page_offset = 1000  # Temporary offset to avoid conflicts
      
      # First pass: move all pages to temp positions
      new_order.each_with_index do |old_page, new_index|
        @document.pdf_elements.by_page(old_page).update_all(
          page_number: new_index + 1 + temp_page_offset
        )
      end
      
      # Second pass: move from temp positions to final positions
      @document.pdf_elements.where('page_number > ?', temp_page_offset).each do |element|
        element.update!(page_number: element.page_number - temp_page_offset)
      end
      
      regenerate_pdf
    end
    
    def apply_snippet(snippet_id, page_number, position = {})
      snippet = PdfSnippet.find(snippet_id)
      
      case snippet.snippet_type
      when 'header'
        apply_header_snippet(snippet, page_number)
      when 'footer'
        apply_footer_snippet(snippet, page_number)
      when 'watermark'
        apply_watermark_snippet(snippet, page_number)
      else
        apply_general_snippet(snippet, page_number, position)
      end
      
      regenerate_pdf
    end
    
    def export(format = :pdf)
      case format
      when :pdf
        regenerate_pdf unless @document.generated_file.attached?
        @document.generated_file
      when :png
        # Would require additional image generation logic
        raise NotImplementedError, "PNG export not yet implemented"
      else
        raise ArgumentError, "Unsupported export format: #{format}"
      end
    end
    
    private
    
    def ensure_page_exists(page_number)
      max_page = @document.pdf_elements.maximum(:page_number) || 0
      
      if page_number > max_page
        (max_page + 1..page_number).each do |page_num|
          # Create hidden placeholder to ensure page exists
          @document.pdf_elements.create!(
            element_type: 'text',
            page_number: page_num,
            x_position: -1000,
            y_position: -1000,
            properties: { content: '', hidden: true }
          )
        end
      end
    end
    
    def regenerate_pdf
      generator = GeneratorService.new(@document)
      generator.generate
    end
    
    def apply_header_snippet(snippet, page_number)
      content = snippet.content || snippet.properties['content']
      
      @document.pdf_elements.create!(
        element_type: 'text',
        page_number: page_number,
        x_position: snippet.properties['x'] || 50,
        y_position: snippet.properties['y'] || 750,
        properties: {
          content: content,
          font_family: snippet.properties['font'] || 'Helvetica',
          font_size: snippet.properties['size'] || 14,
          color: snippet.properties['color'] || '#000000'
        }
      )
    end
    
    def apply_footer_snippet(snippet, page_number)
      content = snippet.content || snippet.properties['content']
      
      @document.pdf_elements.create!(
        element_type: 'text',
        page_number: page_number,
        x_position: snippet.properties['x'] || 50,
        y_position: snippet.properties['y'] || 50,
        properties: {
          content: content,
          font_family: snippet.properties['font'] || 'Helvetica',
          font_size: snippet.properties['size'] || 10,
          color: snippet.properties['color'] || '#666666'
        }
      )
    end
    
    def apply_watermark_snippet(snippet, page_number)
      @document.pdf_elements.create!(
        element_type: 'text',
        page_number: page_number,
        x_position: snippet.properties['x'] || 200,
        y_position: snippet.properties['y'] || 400,
        properties: {
          content: snippet.content,
          font_family: snippet.properties['font'] || 'Helvetica',
          font_size: snippet.properties['size'] || 48,
          color: snippet.properties['color'] || '#CCCCCC',
          rotation: snippet.properties['rotation'] || 45,
          opacity: snippet.properties['opacity'] || 0.3
        }
      )
    end
    
    def apply_general_snippet(snippet, page_number, position)
      # Parse snippet content as JSON if it contains element definitions
      begin
        elements = JSON.parse(snippet.content)
        
        if elements.is_a?(Array)
          elements.each do |element_data|
            @document.pdf_elements.create!(
              element_type: element_data['type'] || 'text',
              page_number: page_number,
              x_position: position[:x] || element_data['x'] || 50,
              y_position: position[:y] || element_data['y'] || 50,
              width: element_data['width'],
              height: element_data['height'],
              properties: element_data['properties'] || {}
            )
          end
        end
      rescue JSON::ParserError
        # If not JSON, treat as simple text content
        @document.pdf_elements.create!(
          element_type: 'text',
          page_number: page_number,
          x_position: position[:x] || 50,
          y_position: position[:y] || 50,
          properties: {
            content: snippet.content
          }.merge(snippet.properties || {})
        )
      end
    end
  end
end