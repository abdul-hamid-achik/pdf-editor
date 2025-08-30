require 'rails_helper'

RSpec.describe PdfElementsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:pdf_document) { create(:pdf_document, user: user) }
  let(:pdf_element) { create(:pdf_element, pdf_document: pdf_document) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    let!(:elements) { create_list(:pdf_element, 3, pdf_document: pdf_document) }

    it 'returns JSON with ordered elements' do
      get :index, params: { pdf_document_id: pdf_document.id }
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
      
      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
    end

    it 'returns elements ordered by page and z_index' do
      element1 = create(:pdf_element, pdf_document: pdf_document, page_number: 2, z_index: 1)
      element2 = create(:pdf_element, pdf_document: pdf_document, page_number: 1, z_index: 2)
      element3 = create(:pdf_element, pdf_document: pdf_document, page_number: 1, z_index: 1)

      get :index, params: { pdf_document_id: pdf_document.id }
      json = JSON.parse(response.body)
      
      expect(json[0]['id']).to eq(element3.id)
      expect(json[1]['id']).to eq(element2.id)
      expect(json[2]['id']).to eq(element1.id)
    end
  end

  describe 'GET #show' do
    it 'returns JSON with element data' do
      get :show, params: { pdf_document_id: pdf_document.id, id: pdf_element.id }
      expect(response).to be_successful
      
      json = JSON.parse(response.body)
      expect(json['id']).to eq(pdf_element.id)
      expect(json['element_type']).to eq(pdf_element.element_type)
    end
  end

  describe 'GET #new' do
    it 'renders element properties partial' do
      expect(controller).to receive(:render).with(
        partial: "pdf/elements/properties/text",
        locals: { element: an_instance_of(PdfElement) }
      )
      
      get :new, params: { pdf_document_id: pdf_document.id, element_type: 'text' }
    end

    it 'builds new element for document' do
      get :new, params: { pdf_document_id: pdf_document.id, element_type: 'text' }
      expect(assigns(:pdf_element).pdf_document).to eq(pdf_document)
      expect(assigns(:pdf_element)).to be_new_record
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
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

    let(:invalid_attributes) do
      {
        element_type: 'invalid_type',
        page_number: 0
      }
    end

    context 'with valid params' do
      it 'creates a new PdfElement' do
        expect {
          post :create, params: { pdf_document_id: pdf_document.id, pdf_element: valid_attributes }
        }.to change(pdf_document.pdf_elements, :count).by(1)
      end

      it 'returns success JSON' do
        post :create, params: { pdf_document_id: pdf_document.id, pdf_element: valid_attributes }
        
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['element']).to be_present
        expect(json['html']).to be_present
      end
    end

    context 'with invalid params' do
      it 'does not create element' do
        expect {
          post :create, params: { pdf_document_id: pdf_document.id, pdf_element: invalid_attributes }
        }.not_to change(PdfElement, :count)
      end

      it 'returns error JSON' do
        post :create, params: { pdf_document_id: pdf_document.id, pdf_element: invalid_attributes }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'GET #edit' do
    it 'renders element properties partial' do
      expect(controller).to receive(:render).with(
        partial: "pdf/elements/properties/#{pdf_element.element_type}",
        locals: { element: pdf_element }
      )
      
      get :edit, params: { pdf_document_id: pdf_document.id, id: pdf_element.id }
    end
  end

  describe 'PATCH #update' do
    let(:new_attributes) do
      {
        x_position: 200,
        y_position: 300,
        properties: { content: 'Updated text' }
      }
    end

    context 'with valid params' do
      it 'updates the element' do
        patch :update, params: { 
          pdf_document_id: pdf_document.id, 
          id: pdf_element.id, 
          pdf_element: new_attributes 
        }
        
        pdf_element.reload
        expect(pdf_element.x_position).to eq(200)
        expect(pdf_element.y_position).to eq(300)
      end

      it 'returns success JSON' do
        patch :update, params: { 
          pdf_document_id: pdf_document.id, 
          id: pdf_element.id, 
          pdf_element: new_attributes 
        }
        
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['element']).to be_present
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) { { element_type: 'invalid' } }

      it 'does not update element' do
        original_type = pdf_element.element_type
        
        patch :update, params: { 
          pdf_document_id: pdf_document.id, 
          id: pdf_element.id, 
          pdf_element: invalid_attributes 
        }
        
        pdf_element.reload
        expect(pdf_element.element_type).to eq(original_type)
      end

      it 'returns error JSON' do
        patch :update, params: { 
          pdf_document_id: pdf_document.id, 
          id: pdf_element.id, 
          pdf_element: invalid_attributes 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the element' do
      pdf_element # create element
      
      expect {
        delete :destroy, params: { pdf_document_id: pdf_document.id, id: pdf_element.id }
      }.to change(PdfElement, :count).by(-1)
    end

    it 'returns success JSON' do
      delete :destroy, params: { pdf_document_id: pdf_document.id, id: pdf_element.id }
      
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end

  describe 'authentication' do
    context 'when not authenticated' do
      before do
        sign_out
      end

      it 'returns unauthorized' do
        get :index, params: { pdf_document_id: pdf_document.id }
        expect(response).to have_http_status(:unauthorized)
        
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'authorization' do
    it 'prevents access to other user documents' do
      other_document = create(:pdf_document, user: other_user)
      
      expect {
        get :index, params: { pdf_document_id: other_document.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'prevents access to other user elements' do
      other_document = create(:pdf_document, user: other_user)
      other_element = create(:pdf_element, pdf_document: other_document)
      
      expect {
        get :show, params: { pdf_document_id: other_document.id, id: other_element.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'private methods' do
    describe '#element_json' do
      it 'returns formatted element data' do
        element = create(:pdf_element, :text, pdf_document: pdf_document)
        json = controller.send(:element_json, element)
        
        expect(json[:id]).to eq(element.id)
        expect(json[:element_type]).to eq(element.element_type)
        expect(json[:position]).to eq({
          x: element.x_position,
          y: element.y_position,
          width: element.width,
          height: element.height
        })
        expect(json[:z_index]).to eq(element.z_index)
        expect(json[:properties]).to eq(element.properties)
      end
    end
  end
end