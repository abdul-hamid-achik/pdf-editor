class PdfElementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pdf_document
  before_action :set_pdf_element, only: [ :show, :edit, :update, :destroy ]

  def index
    @pdf_elements = @pdf_document.pdf_elements.ordered
    render json: @pdf_elements
  end

  def show
    render json: @pdf_element
  end

  def new
    @pdf_element = @pdf_document.pdf_elements.build
    render partial: "pdf/elements/properties/#{params[:element_type]}",
           locals: { element: @pdf_element }
  end

  def create
    @pdf_element = @pdf_document.pdf_elements.build(pdf_element_params)

    if @pdf_element.save
      render json: {
        success: true,
        element: element_json(@pdf_element),
        html: render_element_html(@pdf_element)
      }
    else
      render json: {
        success: false,
        errors: @pdf_element.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def edit
    render partial: "pdf/elements/properties/#{@pdf_element.element_type}",
           locals: { element: @pdf_element }
  end

  def update
    if @pdf_element.update(pdf_element_params)
      render json: {
        success: true,
        element: element_json(@pdf_element)
      }
    else
      render json: {
        success: false,
        errors: @pdf_element.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @pdf_element.destroy!
    render json: { success: true }
  end

  private

  def set_pdf_document
    @pdf_document = current_user.pdf_documents.find(params[:pdf_document_id])
  end

  def set_pdf_element
    @pdf_element = @pdf_document.pdf_elements.find(params[:id])
  end

  def pdf_element_params
    params.require(:pdf_element).permit(
      :element_type, :page_number, :x_position, :y_position,
      :width, :height, :z_index,
      properties: {},
      content: {},
      styles: {},
      position: [ :x, :y, :width, :height ]
    )
  end

  def element_json(element)
    {
      id: element.id,
      element_type: element.element_type,
      page_number: element.page_number,
      position: {
        x: element.x_position,
        y: element.y_position,
        width: element.width,
        height: element.height
      },
      z_index: element.z_index,
      properties: element.properties,
      content: element.content,
      styles: element.styles
    }
  end

  def render_element_html(element)
    render_to_string(
      partial: "pdf/elements/#{element.element_type}",
      locals: { element: element }
    )
  end

  def authenticate_user!
    unless session[:user_id]
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
end
