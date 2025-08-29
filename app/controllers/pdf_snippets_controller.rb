class PdfSnippetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pdf_snippet, only: [ :show, :edit, :update, :destroy ]

  def index
    @pdf_snippets = PdfSnippet.available_for(current_user).includes(:user)
    
    if params[:snippet_type].present?
      @pdf_snippets = @pdf_snippets.by_type(params[:snippet_type])
    end
    
    @pdf_snippets = @pdf_snippets.order(created_at: :desc)
    @snippet_types = PdfSnippet::SNIPPET_TYPES
  end

  def show
  end

  def new
    @pdf_snippet = current_user ? current_user.pdf_snippets.build : PdfSnippet.new
  end

  def create
    @pdf_snippet = current_user ? current_user.pdf_snippets.build(pdf_snippet_params) : PdfSnippet.new(pdf_snippet_params)

    if @pdf_snippet.save
      redirect_to @pdf_snippet, notice: "PDF snippet created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @pdf_snippet.update(pdf_snippet_params)
      redirect_to @pdf_snippet, notice: "Snippet updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pdf_snippet.destroy!
    redirect_to pdf_snippets_path, notice: "Snippet deleted successfully."
  end

  private

  def set_pdf_snippet
    @pdf_snippet = PdfSnippet.find(params[:id])
    
    # Check if user can access this snippet (global or own snippet)
    unless @pdf_snippet.user_id.nil? || @pdf_snippet.user_id == current_user&.id || @pdf_snippet.global?
      redirect_to pdf_snippets_path, alert: "You don't have access to this snippet."
    end
  end

  def pdf_snippet_params
    params.require(:pdf_snippet).permit(
      :name, :snippet_type, :content, :global,
      properties: {}
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
