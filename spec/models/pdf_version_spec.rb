require 'rails_helper'

RSpec.describe PdfVersion, type: :model do
  describe 'associations' do
    it { should belong_to(:pdf_document) }
    it { should belong_to(:user).optional }
  end

  describe 'validations' do
    subject { create(:pdf_version) }
    
    it { should validate_presence_of(:version_number) }
    it { should validate_uniqueness_of(:version_number).scoped_to(:pdf_document_id) }
  end

  describe 'scopes' do
    let(:document) { create(:pdf_document) }
    let!(:version1) { create(:pdf_version, pdf_document: document, version_number: 1) }
    let!(:version3) { create(:pdf_version, pdf_document: document, version_number: 3) }
    let!(:version2) { create(:pdf_version, pdf_document: document, version_number: 2) }

    describe '.ordered' do
      it 'orders by version_number descending' do
        versions = document.pdf_versions.ordered
        expect(versions.map(&:version_number)).to eq([3, 2, 1])
      end
    end
  end

  describe '#description' do
    context 'with version changes' do
      let(:version) do
        create(:pdf_version,
          version_number: 5,
          version_changes: { 'added_pages' => [2, 3], 'updated_elements' => [1, 4] }
        )
      end

      it 'includes version number and changes summary' do
        expect(version.description).to eq('Version 5 - added_pages, updated_elements')
      end
    end

    context 'without version changes' do
      let(:version) do
        create(:pdf_version, version_number: 3, version_changes: nil)
      end

      it 'includes only version number' do
        expect(version.description).to eq('Version 3')
      end
    end

    context 'with empty version changes' do
      let(:version) do
        create(:pdf_version, version_number: 2, version_changes: {})
      end

      it 'includes only version number' do
        expect(version.description).to eq('Version 2')
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:pdf_version)).to be_valid
    end

    it 'creates version without user' do
      version = create(:pdf_version, :without_user)
      expect(version.user).to be_nil
    end

    it 'creates version with major changes' do
      version = create(:pdf_version, :major_changes)
      expect(version.version_changes['added_pages']).to eq([2, 3])
      expect(version.version_changes['layout_changes']).to be true
    end

    it 'creates version with minor changes' do
      version = create(:pdf_version, :minor_changes)
      expect(version.version_changes['updated_elements']).to eq([1])
      expect(version.version_changes['text_edits']).to be true
    end
  end
end