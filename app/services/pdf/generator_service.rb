module Pdf
  class GeneratorService
    attr_reader :document, :pdf

    def initialize(document)
      @document = document
      @pdf = nil # Lazy load PDF document
    end

    def generate
      begin
        @document.update!(status: "processing")
        
        # Initialize PDF document lazily
        @pdf = HexaPDF::Document.new

        apply_template if @document.pdf_template
        setup_pages
        add_elements
        apply_metadata

        output_io = StringIO.new
        output_io.set_encoding(Encoding::BINARY)
        @pdf.write(output_io, optimize: true)
        output_io.rewind

        attach_to_document(output_io)

        @document.update!(
          status: "completed",
          generated_at: Time.current
        )

        @document
      rescue StandardError => e
        @document.update!(status: "failed")
        Rails.logger.error "PDF Generation failed for document #{@document.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end
    end

    private

    def apply_template
      template = @document.pdf_template
      return unless template.structure.present?

      template.increment_usage!

      # Apply template structure
      if template.structure["page_size"]
        @page_size = template.structure["page_size"].to_sym
      end

      if template.structure["margins"]
        @margins = template.structure["margins"]
      end

      # Merge template data with document data
      if template.default_data.present?
        @document.content_data = template.default_data.merge(@document.content_data || {})
      end
    end

    def setup_pages
      # Ensure at least one page exists
      if @document.pdf_elements.empty?
        add_page
      else
        # Add pages based on elements
        max_page = @document.pdf_elements.maximum(:page_number) || 1
        max_page.times { add_page }
      end
    end

    def add_page
      page = @pdf.pages.add(
        @page_size || :A4,
        orientation: :portrait
      )

      if @margins
        page.box = page.box.class.new(
          [
            @margins["left"] || 50,
            @margins["bottom"] || 50,
            page.box.width - (@margins["right"] || 50) - (@margins["left"] || 50),
            page.box.height - (@margins["top"] || 50) - (@margins["bottom"] || 50)
          ]
        )
      end

      page
    end

    def add_elements
      @document.pdf_elements.ordered.each do |element|
        page = @pdf.pages[element.page_number - 1]
        next unless page

        canvas = page.canvas

        case element.element_type
        when "text"
          add_text_element(canvas, element)
        when "image"
          add_image_element(canvas, element)
        when "shape"
          add_shape_element(canvas, element)
        when "line"
          add_line_element(canvas, element)
        when "table"
          add_table_element(canvas, element)
        when "signature"
          add_signature_element(canvas, element)
        end
      end
    end

    def add_text_element(canvas, element)
      props = element.properties.symbolize_keys

      canvas.save_graphics_state do
        # Set font
        font_family = props[:font_family] || "Helvetica"
        font_size = props[:font_size] || 12
        canvas.font(font_family, size: font_size)

        # Set color
        if props[:color]
          color = parse_color(props[:color])
          canvas.fill_color(*color)
        end

        # Add text
        text = interpolate_variables(props[:content] || "")
        canvas.text(
          text,
          at: [ element.x_position || 0, element.y_position || 0 ]
        )
      end
    end

    def add_image_element(canvas, element)
      props = element.properties.symbolize_keys

      if props[:image_url] || props[:image_data]
        begin
          image = if props[:image_data]
            @pdf.images.add(StringIO.new(Base64.decode64(props[:image_data])))
          elsif props[:image_url]
            # Download and add image
            require "open-uri"
            @pdf.images.add(URI.open(props[:image_url]))
          end

          canvas.image(
            image,
            at: [ element.x_position || 0, element.y_position || 0 ],
            width: element.width,
            height: element.height
          )
        rescue StandardError => e
          Rails.logger.error "Failed to add image: #{e.message}"
        end
      end
    end

    def add_shape_element(canvas, element)
      props = element.properties.symbolize_keys

      canvas.save_graphics_state do
        # Set stroke and fill colors
        if props[:stroke_color]
          color = parse_color(props[:stroke_color])
          canvas.stroke_color(*color)
        end

        if props[:fill_color]
          color = parse_color(props[:fill_color])
          canvas.fill_color(*color)
        end

        # Set line width
        canvas.line_width(props[:line_width] || 1)

        # Draw shape
        case props[:shape_type]
        when "rectangle"
          canvas.rectangle(
            element.x_position || 0,
            element.y_position || 0,
            element.width || 100,
            element.height || 100
          )
        when "circle"
          radius = [ element.width, element.height ].min / 2.0
          canvas.circle(
            (element.x_position || 0) + radius,
            (element.y_position || 0) + radius,
            radius
          )
        end

        # Apply stroke and/or fill
        if props[:fill_color] && props[:stroke_color]
          canvas.fill_stroke
        elsif props[:fill_color]
          canvas.fill
        else
          canvas.stroke
        end
      end
    end

    def add_line_element(canvas, element)
      props = element.properties.symbolize_keys

      canvas.save_graphics_state do
        if props[:stroke_color]
          color = parse_color(props[:stroke_color])
          canvas.stroke_color(*color)
        end

        canvas.line_width(props[:line_width] || 1)

        canvas.line(
          element.x_position || 0,
          element.y_position || 0,
          (element.x_position || 0) + (element.width || 100),
          (element.y_position || 0) + (element.height || 0)
        )
        canvas.stroke
      end
    end

    def add_table_element(canvas, element)
      # Simplified table implementation
      props = element.properties.symbolize_keys

      if props[:data].is_a?(Array)
        y_pos = element.y_position || 0
        row_height = props[:row_height] || 20

        props[:data].each do |row|
          x_pos = element.x_position || 0

          if row.is_a?(Array)
            row.each do |cell|
              canvas.text(
                cell.to_s,
                at: [ x_pos, y_pos ]
              )
              x_pos += (element.width || 100) / row.length
            end
          end

          y_pos -= row_height
        end
      end
    end

    def add_signature_element(canvas, element)
      # Placeholder for signature field
      props = element.properties.symbolize_keys

      canvas.save_graphics_state do
        canvas.stroke_color(0.5, 0.5, 0.5)
        canvas.line_width(0.5)
        canvas.rectangle(
          element.x_position || 0,
          element.y_position || 0,
          element.width || 200,
          element.height || 50
        )
        canvas.stroke

        if props[:label]
          canvas.font("Helvetica", size: 10)
          canvas.fill_color(0.3, 0.3, 0.3)
          canvas.text(
            props[:label],
            at: [
              (element.x_position || 0) + 5,
              (element.y_position || 0) - 15
            ]
          )
        end
      end
    end

    def apply_metadata
      info = @pdf.trailer.info
      info[:Title] = @document.title if @document.title.present?
      info[:Author] = @document.user.name || @document.user.email
      info[:Creator] = "PDF Editor - Rails Application"
      info[:Producer] = "HexaPDF"
      info[:CreationDate] = Time.current

      if @document.metadata.present?
        info[:Subject] = @document.metadata["subject"] if @document.metadata["subject"]
        info[:Keywords] = @document.metadata["keywords"] if @document.metadata["keywords"]
      end
    end

    def interpolate_variables(text)
      return text unless @document.content_data.present?

      text.gsub(/\{\{(\w+)\}\}/) do |match|
        key = $1
        @document.content_data[key] || match
      end
    end

    def parse_color(color_string)
      if color_string.start_with?("#")
        # Hex color
        hex = color_string.delete("#")
        r = hex[0..1].to_i(16) / 255.0
        g = hex[2..3].to_i(16) / 255.0
        b = hex[4..5].to_i(16) / 255.0
        [ r, g, b ]
      elsif color_string.include?(",")
        # RGB values
        color_string.split(",").map { |v| v.to_f / 255.0 }
      else
        # Default to black
        [ 0, 0, 0 ]
      end
    end

    def attach_to_document(io)
      @document.generated_file.attach(
        io: io,
        filename: "#{@document.title.parameterize}.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
