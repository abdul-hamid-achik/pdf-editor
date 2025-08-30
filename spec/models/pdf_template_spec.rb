require 'rails_helper'

RSpec.describe PdfTemplate, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:pdf_documents).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'scopes' do
    let!(:business_template) { create(:pdf_template, category: 'business') }
    let!(:education_template) { create(:pdf_template, category: 'education') }
    let!(:popular_template) { create(:pdf_template, :popular) }
    let!(:unpopular_template) { create(:pdf_template, usage_count: 1) }
    let!(:global_template) { create(:pdf_template, :global) }
    let!(:user_template) { create(:pdf_template, :with_user) }

    describe '.by_category' do
      it 'returns templates of specific category' do
        expect(PdfTemplate.by_category('business')).to include(business_template)
        expect(PdfTemplate.by_category('business')).not_to include(education_template)
      end
    end

    describe '.popular' do
      it 'orders by usage_count descending' do
        templates = PdfTemplate.popular
        expect(templates.first.usage_count).to be >= templates.last.usage_count
      end
    end

    describe '.global' do
      it 'returns templates without user' do
        expect(PdfTemplate.global).to include(global_template)
        expect(PdfTemplate.global).not_to include(user_template)
      end
    end
  end

  describe '#increment_usage!' do
    let(:template) { create(:pdf_template, usage_count: 5) }

    it 'increments usage_count by 1' do
      expect { template.increment_usage! }.to change { template.reload.usage_count }.from(5).to(6)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:pdf_template)).to be_valid
    end

    it 'creates global template' do
      template = create(:pdf_template, :global)
      expect(template.user).to be_nil
    end

    it 'creates template with user' do
      template = create(:pdf_template, :with_user)
      expect(template.user).to be_present
    end

    it 'creates popular template' do
      template = create(:pdf_template, :popular)
      expect(template.usage_count).to be >= 100
    end
  end
end