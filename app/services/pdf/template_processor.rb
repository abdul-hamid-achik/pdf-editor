module Pdf
  class TemplateProcessor
    attr_reader :template, :data

    def initialize(template, data = {})
      @template = template
      @data = data.with_indifferent_access
    end

    def process
      document = PdfDocument.new(
        pdf_template: template,
        content_data: merged_data,
        metadata: template.structure["metadata"] || {}
      )

      # Create elements based on template structure
      if template.structure["elements"].is_a?(Array)
        template.structure["elements"].each do |element_def|
          create_element_from_definition(document, element_def)
        end
      end

      document
    end

    def merged_data
      (template.default_data || {}).merge(data)
    end

    private

    def create_element_from_definition(document, definition)
      definition = definition.with_indifferent_access

      # Process any variable replacements in the definition
      processed_def = process_variables(definition)

      document.pdf_elements.build(
        element_type: processed_def["type"] || "text",
        page_number: processed_def["page"] || 1,
        x_position: processed_def["x"] || 0,
        y_position: processed_def["y"] || 0,
        width: processed_def["width"],
        height: processed_def["height"],
        z_index: processed_def["z_index"] || 0,
        properties: processed_def["properties"] || {}
      )
    end

    def process_variables(definition)
      # Deep clone the definition
      processed = definition.deep_dup

      # Recursively process all string values
      process_value(processed)

      processed
    end

    def process_value(value)
      case value
      when String
        interpolate_variables(value)
      when Hash
        value.each do |key, val|
          value[key] = process_value(val)
        end
        value
      when Array
        value.map { |item| process_value(item) }
      else
        value
      end
    end

    def interpolate_variables(text)
      text.gsub(/\{\{(\w+(?:\.\w+)*)\}\}/) do |match|
        key_path = $1.split(".")
        fetch_nested_value(data, key_path) || match
      end
    end

    def fetch_nested_value(hash, keys)
      keys.reduce(hash) do |current, key|
        return nil unless current.is_a?(Hash)
        current[key]
      end
    end
  end
end
