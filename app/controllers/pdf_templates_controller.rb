class PdfTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pdf_template, only: [ :show, :edit, :update, :destroy, :use ]

  def index
    @pdf_templates = PdfTemplate.global.or(PdfTemplate.where(user: current_user))
    @pdf_templates = @pdf_templates.includes(:user).order(created_at: :desc)
    
    if params[:category].present?
      @pdf_templates = @pdf_templates.by_category(params[:category])
    end
  end

  def show
  end

  def new
    @pdf_template = current_user ? current_user.pdf_templates.build : PdfTemplate.new
  end

  def create
    @pdf_template = current_user ? current_user.pdf_templates.build(pdf_template_params) : PdfTemplate.new(pdf_template_params)

    if @pdf_template.save
      redirect_to @pdf_template, notice: "PDF template created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @pdf_template.update(pdf_template_params)
      redirect_to @pdf_template, notice: "Template updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pdf_template.destroy!
    redirect_to pdf_templates_path, notice: "Template deleted successfully."
  end

  def use
    # Increment usage counter
    @pdf_template.increment_usage!
    
    # Redirect to create new document with this template
    redirect_to new_pdf_document_path(template_id: @pdf_template.id),
      notice: "Template selected. Create your document below."
  end

  private

  def set_pdf_template
    @pdf_template = PdfTemplate.find(params[:id])
    
    # Check if user can access this template (global or own template)
    unless @pdf_template.user_id.nil? || @pdf_template.user_id == current_user&.id
      redirect_to pdf_templates_path, alert: "You don't have access to this template."
    end
  end

  def pdf_template_params
    params.require(:pdf_template).permit(
      :name, :description, :category, :thumbnail_url,
      structure: {},
      default_data: {}
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
