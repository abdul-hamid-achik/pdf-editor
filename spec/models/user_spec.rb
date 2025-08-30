require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:pdf_templates).dependent(:destroy) }
    it { is_expected.to have_many(:pdf_snippets).dependent(:destroy) }
    it { is_expected.to have_many(:pdf_documents).dependent(:destroy) }
    it { is_expected.to have_many(:pdf_versions).dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
    
    context 'for new record' do
      it { should validate_presence_of(:password) }
      it { should validate_length_of(:password).is_at_least(6) }
    end

    context 'for existing record without password change' do
      let(:user) { create(:user) }
      
      it 'does not require password' do
        user.email = 'newemail@example.com'
        expect(user).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save' do
      it 'downcases email' do
        user = build(:user, email: 'TEST@EXAMPLE.COM')
        user.save
        expect(user.reload.email).to eq('test@example.com')
      end
    end
  end

  describe 'has_secure_password' do
    let(:user) { build(:user, password: 'password123', password_confirmation: 'password123') }

    it 'authenticates with correct password' do
      user.save
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user.save
      expect(user.authenticate('wrong_password')).to be_falsey
    end
  end

  describe '#password_required?' do
    context 'for new record' do
      let(:user) { build(:user) }

      it 'returns true' do
        expect(user.send(:password_required?)).to be true
      end
    end

    context 'for existing record without password' do
      let(:user) { create(:user) }

      it 'returns false when password is blank' do
        user.password = nil
        expect(user.send(:password_required?)).to be false
      end

      it 'returns true when password is present' do
        user.password = 'newpassword'
        expect(user.send(:password_required?)).to be true
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end

    it 'creates user with documents' do
      user = create(:user, :with_documents)
      expect(user.pdf_documents.count).to eq(3)
    end

    it 'creates user with templates' do
      user = create(:user, :with_templates)
      expect(user.pdf_templates.count).to eq(2)
    end

    it 'creates user with snippets' do
      user = create(:user, :with_snippets)
      expect(user.pdf_snippets.count).to eq(3)
    end
  end
end