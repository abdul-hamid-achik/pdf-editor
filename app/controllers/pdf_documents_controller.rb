class PdfDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pdf_document, only: [ :show, :edit, :update, :destroy, :generate, :preview, :duplicate ]

  def index
    @pdf_documents = current_user.pdf_documents.includes(:pdf_template)
    @pdf_documents = @pdf_documents.where(status: params[:status]) if params[:status].present?
    @pdf_documents = @pdf_documents.order(created_at: :desc)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        if @pdf_document.generated_file.attached?
          redirect_to rails_blob_url(@pdf_document.generated_file, disposition: "inline")
        else
          redirect_to pdf_documents_path, alert: "PDF not yet generated"
        end
      end
    end
  end

  def new
    @pdf_document = current_user.pdf_documents.build
    @pdf_document.pdf_template_id = params[:template_id] if params[:template_id].present?

    if @pdf_document.pdf_template
      # Apply template
      processor = Pdf::TemplateProcessor.new(@pdf_document.pdf_template)
      template_doc = processor.process
      @pdf_document.attributes = template_doc.attributes.except("id", "created_at", "updated_at")
      @pdf_document.pdf_elements = template_doc.pdf_elements
    end

    @templates = PdfTemplate.global.or(PdfTemplate.where(user: current_user))
  end

  def create
    @pdf_document = current_user.pdf_documents.build(pdf_document_params)

    if @pdf_document.save
      redirect_to edit_pdf_document_path(@pdf_document), notice: "PDF document created successfully."
    else
      @templates = PdfTemplate.global.or(PdfTemplate.where(user: current_user))
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @templates = PdfTemplate.global.or(PdfTemplate.where(user: current_user))
    @snippets = PdfSnippet.available_for(current_user)
  end

  def update
    respond_to do |format|
      if @pdf_document.update(pdf_document_params)
        format.html { redirect_to @pdf_document, notice: "Document updated successfully." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("pdf_document_#{@pdf_document.id}",
              partial: "pdf_documents/document",
              locals: { pdf_document: @pdf_document }),
            turbo_stream.update("flash", partial: "shared/flash",
              locals: { notice: "Document saved" })
          ]
        end
        format.json { render json: @pdf_document }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pdf_document.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @pdf_document.destroy!
    redirect_to pdf_documents_path, notice: "Document deleted successfully."
  end

  def generate
    @pdf_document.generate_pdf!

    respond_to do |format|
      format.html { redirect_to @pdf_document, notice: "PDF generation started." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "pdf_document_status_#{@pdf_document.id}",
          partial: "pdf_documents/status",
          locals: { pdf_document: @pdf_document }
        )
      end
    end
  end

  def preview
    generator = Pdf::PreviewGenerator.new(@pdf_document)

    respond_to do |format|
      format.html do
        @preview_html = generator.generate_preview(format: :html, page: params[:page]&.to_i)
        render partial: "pdf_documents/preview", locals: { preview_html: @preview_html }
      end
      format.json do
        render json: generator.generate_preview(format: :json, page: params[:page]&.to_i)
      end
      format.pdf do
        preview_io = generator.generate_preview(format: :pdf, page: params[:page]&.to_i)
        send_data preview_io.read,
          filename: "#{@pdf_document.title}_preview.pdf",
          type: "application/pdf",
          disposition: "inline"
      end
    end
  end

  def duplicate
    new_document = @pdf_document.duplicate
    new_document.user = current_user
    new_document.title = "#{@pdf_document.title} (Copy)"

    if new_document.save
      redirect_to edit_pdf_document_path(new_document),
        notice: "Document duplicated successfully."
    else
      redirect_to @pdf_document, alert: "Failed to duplicate document."
    end
  end

  private

  def set_pdf_document
    @pdf_document = current_user.pdf_documents.find(params[:id])
  end

  def pdf_document_params
    params.require(:pdf_document).permit(
      :title, :description, :pdf_template_id,
      metadata: {},
      content_data: {},
      pdf_elements_attributes: [ :id, :element_type, :page_number, :x_position,
        :y_position, :width, :height, :z_index, :_destroy, properties: {} ]
    )
  end

  def authenticate_user!
    # Placeholder for authentication
    # Will be replaced with actual authentication later
    unless session[:user_id]
      redirect_to root_path, alert: "Please sign in to continue"
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user
end
