require 'rails_helper'

RSpec.describe PdfSnippet, type: :model do
  describe 'associations' do
    it { should belong_to(:user).optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:snippet_type).in_array(PdfSnippet::SNIPPET_TYPES).allow_blank }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:header_snippet) { create(:pdf_snippet, :header, user: user) }
    let!(:footer_snippet) { create(:pdf_snippet, :footer, user: user) }
    let!(:global_snippet) { create(:pdf_snippet, :global, :watermark) }
    let!(:user_snippet) { create(:pdf_snippet, user: user) }
    let!(:other_user_snippet) { create(:pdf_snippet, user: other_user) }

    describe '.by_type' do
      it 'returns snippets of specific type' do
        expect(PdfSnippet.by_type('header')).to contain_exactly(header_snippet)
        expect(PdfSnippet.by_type('footer')).to contain_exactly(footer_snippet)
      end
    end

    describe '.global_snippets' do
      it 'returns only global snippets' do
        expect(PdfSnippet.global_snippets).to contain_exactly(global_snippet)
      end
    end

    describe '.user_snippets' do
      it 'returns snippets for specific user' do
        expect(PdfSnippet.user_snippets(user)).to contain_exactly(header_snippet, footer_snippet, user_snippet)
      end
    end

    describe '.available_for' do
      it 'returns user snippets, nil user snippets, and global snippets' do
        nil_user_snippet = create(:pdf_snippet, user: nil, global: false)
        
        available = PdfSnippet.available_for(user)
        expect(available).to include(header_snippet, footer_snippet, user_snippet, global_snippet, nil_user_snippet)
        expect(available).not_to include(other_user_snippet)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:pdf_snippet)).to be_valid
    end

    describe 'traits' do
      it 'creates global snippet' do
        snippet = create(:pdf_snippet, :global)
        expect(snippet.global).to be true
        expect(snippet.user).to be_nil
      end

      it 'creates snippet with user' do
        snippet = create(:pdf_snippet, :with_user)
        expect(snippet.user).to be_present
      end

      it 'creates header snippet' do
        snippet = create(:pdf_snippet, :header)
        expect(snippet.snippet_type).to eq('header')
        expect(snippet.content['elements']).to be_present
      end

      it 'creates footer snippet' do
        snippet = create(:pdf_snippet, :footer)
        expect(snippet.snippet_type).to eq('footer')
        expect(snippet.content['elements'].first['content']).to include('page_number')
      end

      it 'creates watermark snippet' do
        snippet = create(:pdf_snippet, :watermark)
        expect(snippet.snippet_type).to eq('watermark')
        expect(snippet.content['elements'].first['content']).to eq('CONFIDENTIAL')
      end

      it 'creates signature snippet' do
        snippet = create(:pdf_snippet, :signature)
        expect(snippet.snippet_type).to eq('signature')
        expect(snippet.content['elements'].first['type']).to eq('signature')
      end
    end
  end
end