require 'rails_helper'

RSpec.describe PdfElement, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:pdf_document) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:element_type).in_array(PdfElement::ELEMENT_TYPES) }
    it { is_expected.to validate_numericality_of(:page_number).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:z_index).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let(:document) { create(:pdf_document) }
    let!(:page1_element) { create(:pdf_element, pdf_document: document, page_number: 1, z_index: 1) }
    let!(:page2_element) { create(:pdf_element, pdf_document: document, page_number: 2, z_index: 0) }
    let!(:text_element) { create(:pdf_element, :text, pdf_document: document) }
    let!(:image_element) { create(:pdf_element, :image, pdf_document: document) }

    describe '.by_page' do
      it 'returns elements for specific page' do
        expect(document.pdf_elements.by_page(1)).to include(page1_element)
        expect(document.pdf_elements.by_page(1)).not_to include(page2_element)
      end
    end

    describe '.ordered' do
      it 'orders by page number and z_index' do
        elements = document.pdf_elements.ordered
        expect(elements.first.page_number).to be <= elements.last.page_number
      end
    end

    describe '.by_type' do
      it 'returns elements of specific type' do
        expect(document.pdf_elements.by_type('text')).to include(text_element)
        expect(document.pdf_elements.by_type('text')).not_to include(image_element)
      end
    end
  end

  describe '#content and #content=' do
    let(:element) { create(:pdf_element) }

    it 'gets content from properties' do
      element.properties = { 'content' => { 'text' => 'Hello' } }
      expect(element.content).to eq({ 'text' => 'Hello' })
    end

    it 'sets content in properties' do
      element.content = { 'text' => 'World' }
      expect(element.properties['content']).to eq({ 'text' => 'World' })
    end

    it 'returns empty hash when content is nil' do
      element.properties = {}
      expect(element.content).to eq({})
    end
  end

  describe '#styles and #styles=' do
    let(:element) { create(:pdf_element) }

    it 'gets styles from properties' do
      element.properties = { 'styles' => { 'color' => '#000' } }
      expect(element.styles).to eq({ 'color' => '#000' })
    end

    it 'sets styles in properties' do
      element.styles = { 'font_size' => 12 }
      expect(element.properties['styles']).to eq({ 'font_size' => 12 })
    end

    it 'returns empty hash when styles is nil' do
      element.properties = {}
      expect(element.styles).to eq({})
    end
  end

  describe '#render_properties' do
    let(:element) do
      create(:pdf_element,
        element_type: 'text',
        x_position: 100,
        y_position: 200,
        width: 150,
        height: 50,
        properties: { 'content' => 'Test', 'styles' => { 'color' => 'red' } }
      )
    end

    it 'returns formatted properties for rendering' do
      props = element.render_properties
      expect(props[:type]).to eq('text')
      expect(props[:position]).to eq({ x: 100, y: 200 })
      expect(props[:dimensions]).to eq({ width: 150, height: 50 })
      expect(props[:content]).to eq('Test')
      expect(props[:styles]).to eq({ 'color' => 'red' })
    end
  end

  describe '#move_to' do
    let(:element) { create(:pdf_element, x_position: 10, y_position: 20) }

    it 'updates position' do
      element.move_to(100, 200)
      element.reload
      expect(element.x_position).to eq(100)
      expect(element.y_position).to eq(200)
    end
  end

  describe '#resize' do
    let(:element) { create(:pdf_element, width: 50, height: 30) }

    it 'updates dimensions' do
      element.resize(200, 100)
      element.reload
      expect(element.width).to eq(200)
      expect(element.height).to eq(100)
    end
  end

  describe '#bring_to_front' do
    let(:document) { create(:pdf_document) }
    let!(:element1) { create(:pdf_element, pdf_document: document, page_number: 1, z_index: 0) }
    let!(:element2) { create(:pdf_element, pdf_document: document, page_number: 1, z_index: 1) }
    let!(:element3) { create(:pdf_element, pdf_document: document, page_number: 1, z_index: 2) }

    it 'sets z_index to highest + 1' do
      element1.bring_to_front
      element1.reload
      expect(element1.z_index).to eq(3)
    end
  end

  describe '#send_to_back' do
    let(:document) { create(:pdf_document) }
    let!(:element1) { create(:pdf_element, pdf_document: document, page_number: 1, z_index: 2) }
    let!(:element2) { create(:pdf_element, pdf_document: document, page_number: 1, z_index: 1) }
    let!(:element3) { create(:pdf_element, pdf_document: document, page_number: 1, z_index: 3) }

    it 'sets z_index to 0 and increments others' do
      element3.send_to_back
      
      element1.reload
      element2.reload
      element3.reload
      
      expect(element3.z_index).to eq(0)
      expect(element1.z_index).to eq(3)
      expect(element2.z_index).to eq(2)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:pdf_element)).to be_valid
    end

    describe 'traits' do
      it 'creates text element' do
        element = create(:pdf_element, :text)
        expect(element.element_type).to eq('text')
        expect(element.properties['content']).to be_present
      end

      it 'creates image element' do
        element = create(:pdf_element, :image)
        expect(element.element_type).to eq('image')
        expect(element.properties['content']['url']).to be_present
      end

      it 'creates shape element' do
        element = create(:pdf_element, :shape)
        expect(element.element_type).to eq('shape')
        expect(element.properties['styles']['fill_color']).to be_present
      end

      it 'creates table element' do
        element = create(:pdf_element, :table)
        expect(element.element_type).to eq('table')
        expect(element.properties['content']['data']).to be_present
      end

      it 'creates signature element' do
        element = create(:pdf_element, :signature)
        expect(element.element_type).to eq('signature')
        expect(element.properties['content']['signature_data']).to be_present
      end
    end
  end
end