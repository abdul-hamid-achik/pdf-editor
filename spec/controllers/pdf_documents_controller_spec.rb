require 'rails_helper'

RSpec.describe PdfDocumentsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:pdf_document) { create(:pdf_document, user: user) }
  let(:template) { create(:pdf_template, :global) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    let!(:user_documents) { create_list(:pdf_document, 3, user: user) }
    let!(:other_documents) { create_list(:pdf_document, 2, user: other_user) }

    it 'returns success' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns current user documents' do
      get :index
      expect(assigns(:pdf_documents)).to match_array(user_documents)
    end

    it 'filters by status when provided' do
      completed_doc = create(:pdf_document, :completed, user: user)
      draft_doc = create(:pdf_document, status: 'draft', user: user)

      get :index, params: { status: 'completed' }
      expect(assigns(:pdf_documents)).to contain_exactly(completed_doc)
    end

    it 'orders documents by created_at desc' do
      get :index
      documents = assigns(:pdf_documents)
      expect(documents).to eq(documents.sort_by(&:created_at).reverse)
    end
  end

  describe 'GET #show' do
    context 'with HTML format' do
      it 'returns success' do
        get :show, params: { id: pdf_document.id }
        expect(response).to be_successful
      end
    end

    context 'with PDF format' do
      context 'when generated file exists' do
        before do
          pdf_document.generated_file.attach(
            io: StringIO.new("PDF content"),
            filename: "document.pdf",
            content_type: "application/pdf"
          )
        end

        it 'redirects to generated file' do
          get :show, params: { id: pdf_document.id }, format: :pdf
          expect(response).to redirect_to(rails_blob_url(pdf_document.generated_file, disposition: "inline"))
        end
      end

      context 'when generated file does not exist' do
        it 'redirects with alert' do
          get :show, params: { id: pdf_document.id }, format: :pdf
          expect(response).to redirect_to(pdf_documents_path)
          expect(flash[:alert]).to eq("PDF not yet generated")
        end
      end
    end

    context 'accessing other user document' do
      it 'raises not found error' do
        other_doc = create(:pdf_document, user: other_user)
        expect {
          get :show, params: { id: other_doc.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET #new' do
    it 'returns success' do
      get :new
      expect(response).to be_successful
    end

    it 'builds new document for current user' do
      get :new
      expect(assigns(:pdf_document).user).to eq(user)
      expect(assigns(:pdf_document)).to be_new_record
    end

    context 'with template_id' do
      it 'assigns template to document' do
        get :new, params: { template_id: template.id }
        expect(assigns(:pdf_document).pdf_template_id).to eq(template.id)
      end

      it 'processes template' do
        expect_any_instance_of(Pdf::TemplateProcessor).to receive(:process).and_call_original
        get :new, params: { template_id: template.id }
      end
    end

    it 'assigns available templates' do
      user_template = create(:pdf_template, user: user)
      get :new
      expect(assigns(:templates)).to include(template, user_template)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        title: "New Document",
        description: "Test description",
        metadata: { pages: 1 }
      }
    end

    let(:invalid_attributes) do
      {
        title: "",
        status: "invalid_status"
      }
    end

    context 'with valid params' do
      it 'creates a new PdfDocument' do
        expect {
          post :create, params: { pdf_document: valid_attributes }
        }.to change(PdfDocument, :count).by(1)
      end

      it 'assigns document to current user' do
        post :create, params: { pdf_document: valid_attributes }
        expect(PdfDocument.last.user).to eq(user)
      end

      it 'redirects to edit page' do
        post :create, params: { pdf_document: valid_attributes }
        expect(response).to redirect_to(edit_pdf_document_path(PdfDocument.last))
      end
    end

    context 'with invalid params' do
      it 'does not create document' do
        expect {
          post :create, params: { pdf_document: invalid_attributes }
        }.not_to change(PdfDocument, :count)
      end

      it 'renders new template' do
        post :create, params: { pdf_document: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns success' do
      get :edit, params: { id: pdf_document.id }
      expect(response).to be_successful
    end

    it 'assigns templates and snippets' do
      snippet = create(:pdf_snippet, user: user)
      get :edit, params: { id: pdf_document.id }
      expect(assigns(:templates)).to include(template)
      expect(assigns(:snippets)).to include(snippet)
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) do
      {
        title: "Updated Title",
        description: "Updated description"
      }
    end

    context 'with valid params' do
      it 'updates the document' do
        patch :update, params: { id: pdf_document.id, pdf_document: new_attributes }
        pdf_document.reload
        expect(pdf_document.title).to eq("Updated Title")
        expect(pdf_document.description).to eq("Updated description")
      end

      context 'HTML format' do
        it 'redirects to document' do
          patch :update, params: { id: pdf_document.id, pdf_document: new_attributes }
          expect(response).to redirect_to(pdf_document)
        end
      end

      context 'JSON format' do
        it 'returns document as JSON' do
          patch :update, params: { id: pdf_document.id, pdf_document: new_attributes }, format: :json
          expect(response).to be_successful
          expect(JSON.parse(response.body)['title']).to eq("Updated Title")
        end
      end

      context 'Turbo Stream format' do
        it 'renders turbo stream' do
          patch :update, params: { id: pdf_document.id, pdf_document: new_attributes }, format: :turbo_stream
          expect(response).to be_successful
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) { { status: "invalid" } }

      it 'does not update document' do
        original_status = pdf_document.status
        patch :update, params: { id: pdf_document.id, pdf_document: invalid_attributes }
        pdf_document.reload
        expect(pdf_document.status).to eq(original_status)
      end

      context 'HTML format' do
        it 'renders edit template' do
          patch :update, params: { id: pdf_document.id, pdf_document: invalid_attributes }
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'JSON format' do
        it 'returns errors as JSON' do
          patch :update, params: { id: pdf_document.id, pdf_document: invalid_attributes }, format: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to have_key('status')
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the document' do
      pdf_document # create document
      expect {
        delete :destroy, params: { id: pdf_document.id }
      }.to change(PdfDocument, :count).by(-1)
    end

    it 'redirects to documents list' do
      delete :destroy, params: { id: pdf_document.id }
      expect(response).to redirect_to(pdf_documents_path)
    end
  end

  describe 'POST #generate' do
    it 'calls generate_pdf! on document' do
      expect_any_instance_of(PdfDocument).to receive(:generate_pdf!)
      post :generate, params: { id: pdf_document.id }
    end

    context 'HTML format' do
      it 'redirects to document' do
        post :generate, params: { id: pdf_document.id }
        expect(response).to redirect_to(pdf_document)
        expect(flash[:notice]).to eq("PDF generation started.")
      end
    end

    context 'Turbo Stream format' do
      it 'renders turbo stream' do
        post :generate, params: { id: pdf_document.id }, format: :turbo_stream
        expect(response).to be_successful
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end

  describe 'GET #preview' do
    let(:preview_generator) { instance_double(Pdf::PreviewGenerator) }

    before do
      allow(Pdf::PreviewGenerator).to receive(:new).and_return(preview_generator)
    end

    context 'HTML format' do
      it 'generates HTML preview' do
        expect(preview_generator).to receive(:generate_preview)
          .with(format: :html, page: nil)
          .and_return("<div>Preview</div>")
        
        get :preview, params: { id: pdf_document.id }, format: :html
        expect(response).to be_successful
      end
    end

    context 'JSON format' do
      it 'generates JSON preview' do
        expect(preview_generator).to receive(:generate_preview)
          .with(format: :json, page: nil)
          .and_return({ preview: "data" })
        
        get :preview, params: { id: pdf_document.id }, format: :json
        expect(response).to be_successful
      end
    end

    context 'PDF format' do
      it 'sends PDF preview' do
        pdf_io = StringIO.new("PDF content")
        expect(preview_generator).to receive(:generate_preview)
          .with(format: :pdf, page: nil)
          .and_return(pdf_io)
        
        get :preview, params: { id: pdf_document.id }, format: :pdf
        expect(response.headers['Content-Type']).to include('application/pdf')
      end
    end

    it 'accepts page parameter' do
      expect(preview_generator).to receive(:generate_preview)
        .with(format: :html, page: 2)
        .and_return("<div>Page 2</div>")
      
      get :preview, params: { id: pdf_document.id, page: "2" }, format: :html
    end
  end

  describe 'POST #duplicate' do
    it 'creates duplicate document' do
      expect {
        post :duplicate, params: { id: pdf_document.id }
      }.to change(PdfDocument, :count).by(1)
    end

    it 'assigns duplicate to current user' do
      post :duplicate, params: { id: pdf_document.id }
      duplicate = PdfDocument.last
      expect(duplicate.user).to eq(user)
    end

    it 'appends (Copy) to title' do
      post :duplicate, params: { id: pdf_document.id }
      duplicate = PdfDocument.last
      expect(duplicate.title).to eq("#{pdf_document.title} (Copy)")
    end

    it 'redirects to edit duplicate' do
      post :duplicate, params: { id: pdf_document.id }
      expect(response).to redirect_to(edit_pdf_document_path(PdfDocument.last))
    end

    context 'when duplication fails' do
      before do
        allow_any_instance_of(PdfDocument).to receive(:save).and_return(false)
      end

      it 'redirects back with alert' do
        post :duplicate, params: { id: pdf_document.id }
        expect(response).to redirect_to(pdf_document)
        expect(flash[:alert]).to eq("Failed to duplicate document.")
      end
    end
  end

  describe 'authentication' do
    context 'when not authenticated' do
      before do
        sign_out
      end

      it 'redirects to root path' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please sign in to continue")
      end
    end
  end
end