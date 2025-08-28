module Pdf
  class PreviewGenerator
    attr_reader :document

    def initialize(document)
      @document = document
    end

    def generate_preview(format: :pdf, page: nil)
      case format
      when :pdf
        generate_pdf_preview(page)
      when :json
        generate_json_preview(page)
      when :html
        generate_html_preview(page)
      else
        raise ArgumentError, "Unsupported preview format: #{format}"
      end
    end

    private

    def generate_pdf_preview(page = nil)
      # Generate a lightweight PDF for preview
      pdf = HexaPDF::Document.new

      pages_to_render = if page
        [ page ]
      else
        (1..max_page_number).to_a
      end

      pages_to_render.each do |page_num|
        pdf_page = pdf.pages.add
        canvas = pdf_page.canvas

        # Render elements for this page
        @document.pdf_elements.by_page(page_num).ordered.each do |element|
          render_element_preview(canvas, element)
        end
      end

      output_io = StringIO.new
      output_io.set_encoding(Encoding::BINARY)
      pdf.write(output_io)
      output_io.rewind

      output_io
    end

    def generate_json_preview(page = nil)
      elements = if page
        @document.pdf_elements.by_page(page)
      else
        @document.pdf_elements
      end

      {
        document: {
          id: @document.id,
          title: @document.title,
          status: @document.status,
          pages: page ? 1 : max_page_number
        },
        elements: elements.ordered.map do |element|
          {
            id: element.id,
            type: element.element_type,
            page: element.page_number,
            position: {
              x: element.x_position,
              y: element.y_position
            },
            dimensions: {
              width: element.width,
              height: element.height
            },
            z_index: element.z_index,
            properties: element.properties
          }
        end
      }
    end

    def generate_html_preview(page = nil)
      elements = if page
        @document.pdf_elements.by_page(page)
      else
        @document.pdf_elements
      end

      html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            .pdf-page {
              width: 595px;
              height: 842px;
              margin: 20px auto;
              background: white;
              box-shadow: 0 0 10px rgba(0,0,0,0.1);
              position: relative;
              page-break-after: always;
            }
            .pdf-element {
              position: absolute;
            }
            .pdf-text {
              font-family: Helvetica, Arial, sans-serif;
            }
            .pdf-shape {
              border: 1px solid #000;
            }
          </style>
        </head>
        <body style="background: #f5f5f5;">
      HTML

      pages_to_render = if page
        [ page ]
      else
        (1..max_page_number).to_a
      end

      pages_to_render.each do |page_num|
        html += %Q(<div class="pdf-page" data-page="#{page_num}">)

        elements.by_page(page_num).ordered.each do |element|
          html += render_element_html(element)
        end

        html += "</div>"
      end

      html += <<~HTML
        </body>
        </html>
      HTML

      html
    end

    def render_element_preview(canvas, element)
      case element.element_type
      when "text"
        props = element.properties.symbolize_keys
        canvas.save_graphics_state do
          canvas.font(props[:font_family] || "Helvetica", size: props[:font_size] || 12)
          canvas.text(
            props[:content] || "",
            at: [ element.x_position || 0, element.y_position || 0 ]
          )
        end
      when "shape"
        props = element.properties.symbolize_keys
        canvas.save_graphics_state do
          canvas.stroke_color(0, 0, 0)

          case props[:shape_type]
          when "rectangle"
            canvas.rectangle(
              element.x_position || 0,
              element.y_position || 0,
              element.width || 100,
              element.height || 100
            )
            canvas.stroke
          when "circle"
            radius = [ element.width || 50, element.height || 50 ].min / 2.0
            canvas.circle(
              (element.x_position || 0) + radius,
              (element.y_position || 0) + radius,
              radius
            )
            canvas.stroke
          end
        end
      end
    end

    def render_element_html(element)
      style = "left: #{element.x_position || 0}px; " \
              "top: #{element.y_position || 0}px; " \
              "z-index: #{element.z_index};"

      case element.element_type
      when "text"
        props = element.properties.symbolize_keys
        font_size = props[:font_size] || 12
        color = props[:color] || "#000000"

        style += "font-size: #{font_size}px; color: #{color};"

        %Q(<div class="pdf-element pdf-text" style="#{style}">#{ERB::Util.html_escape(props[:content] || '')}</div>)
      when "shape"
        props = element.properties.symbolize_keys

        style += "width: #{element.width || 100}px; " \
                "height: #{element.height || 100}px;"

        if props[:shape_type] == "circle"
          style += "border-radius: 50%;"
        end

        if props[:fill_color]
          style += "background-color: #{props[:fill_color]};"
        end

        if props[:stroke_color]
          style += "border-color: #{props[:stroke_color]};"
        end

        %Q(<div class="pdf-element pdf-shape" style="#{style}"></div>)
      when "image"
        props = element.properties.symbolize_keys

        style += "width: #{element.width || 100}px; " \
                "height: #{element.height || 100}px;"

        src = props[:image_url] || "data:image/png;base64,#{props[:image_data]}"

        %Q(<img class="pdf-element pdf-image" src="#{src}" style="#{style}" />)
      else
        ""
      end
    end

    def max_page_number
      @document.pdf_elements.maximum(:page_number) || 1
    end
  end
end
