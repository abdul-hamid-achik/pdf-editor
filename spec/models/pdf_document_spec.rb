require 'rails_helper'

RSpec.describe PdfDocument, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:pdf_template).optional }
    it { should have_many(:pdf_elements).dependent(:destroy) }
    it { should have_many(:pdf_versions).dependent(:destroy) }
    it { should have_one_attached(:generated_file) }
  end

  describe 'validations' do
    it { should validate_inclusion_of(:status).in_array(PdfDocument::STATUSES) }
  end

  describe 'scopes' do
    let!(:draft_doc) { create(:pdf_document, status: 'draft') }
    let!(:completed_doc) { create(:pdf_document, :completed) }
    let!(:processing_doc) { create(:pdf_document, :processing) }
    let!(:failed_doc) { create(:pdf_document, :failed) }

    describe '.drafts' do
      it 'returns only draft documents' do
        expect(PdfDocument.drafts).to contain_exactly(draft_doc)
      end
    end

    describe '.completed' do
      it 'returns only completed documents' do
        expect(PdfDocument.completed).to contain_exactly(completed_doc)
      end
    end

    describe '.processing' do
      it 'returns only processing documents' do
        expect(PdfDocument.processing).to contain_exactly(processing_doc)
      end
    end

    describe '.failed' do
      it 'returns only failed documents' do
        expect(PdfDocument.failed).to contain_exactly(failed_doc)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_create' do
      context 'when title is not provided' do
        it 'sets a default title' do
          document = build(:pdf_document, title: nil)
          document.save
          expect(document.title).to match(/^Untitled Document \d{4}-\d{2}-\d{2}$/)
        end
      end

      context 'when title is provided' do
        it 'keeps the provided title' do
          document = build(:pdf_document, title: 'My Document')
          document.save
          expect(document.title).to eq('My Document')
        end
      end
    end
  end

  describe '#generate_pdf!' do
    let(:document) { create(:pdf_document) }

    it 'updates status to processing' do
      expect { document.generate_pdf! }.to change { document.status }.to('processing')
    end

    it 'enqueues PdfGenerationJob' do
      expect(PdfGenerationJob).to receive(:perform_later).with(document)
      document.generate_pdf!
    end
  end

  describe '#add_element' do
    let(:document) { create(:pdf_document) }
    let(:element_params) do
      {
        element_type: 'text',
        page_number: 1,
        x_position: 100,
        y_position: 200,
        width: 150,
        height: 50,
        z_index: 1,
        properties: { content: 'Test text' }
      }
    end

    it 'creates a new pdf element' do
      expect { document.add_element(element_params) }.to change { document.pdf_elements.count }.by(1)
    end

    it 'creates element with correct attributes' do
      element = document.add_element(element_params)
      expect(element.element_type).to eq('text')
      expect(element.x_position).to eq(100)
      expect(element.properties['content']).to eq('Test text')
    end
  end

  describe '#duplicate' do
    let!(:original) { create(:pdf_document, :with_elements, title: 'Original') }

    it 'creates a new document with same attributes' do
      duplicate = original.duplicate
      expect(duplicate).to be_new_record
      expect(duplicate.title).to eq('Original')
      expect(duplicate.user_id).to eq(original.user_id)
    end

    it 'duplicates all pdf elements' do
      duplicate = original.duplicate
      expect(duplicate.pdf_elements.size).to eq(original.pdf_elements.size)
    end

    it 'does not copy timestamps and generated_at' do
      original.update(generated_at: Time.current)
      duplicate = original.duplicate
      expect(duplicate.generated_at).to be_nil
    end
  end

  describe '#create_version!' do
    let(:document) { create(:pdf_document) }
    let(:user) { create(:user) }

    context 'when no versions exist' do
      it 'creates version with number 1' do
        version = document.create_version!(user: user, changes: { updated: true })
        expect(version.version_number).to eq(1)
      end
    end

    context 'when versions exist' do
      before do
        create(:pdf_version, pdf_document: document, version_number: 1)
        create(:pdf_version, pdf_document: document, version_number: 2)
      end

      it 'increments version number' do
        version = document.create_version!(user: user, changes: { updated: true })
        expect(version.version_number).to eq(3)
      end
    end

    it 'stores version changes' do
      changes = { added_elements: [1, 2], removed_elements: [3] }
      version = document.create_version!(user: user, changes: changes)
      expect(version.version_changes).to eq(changes.stringify_keys)
    end

    it 'associates with user' do
      version = document.create_version!(user: user, changes: {})
      expect(version.user).to eq(user)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:pdf_document)).to be_valid
    end

    it 'creates document with elements' do
      document = create(:pdf_document, :with_elements)
      expect(document.pdf_elements.count).to eq(5)
    end

    it 'creates document with versions' do
      document = create(:pdf_document, :with_versions)
      expect(document.pdf_versions.count).to eq(3)
    end

    it 'creates document with generated file' do
      document = create(:pdf_document, :with_generated_file)
      expect(document.generated_file).to be_attached
    end
  end
end