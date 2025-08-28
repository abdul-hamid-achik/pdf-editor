class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_user

  private

  def set_current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def current_user
    @current_user
  end
  helper_method :current_user

  def logged_in?
    !!current_user
  end
  helper_method :logged_in?

  def require_login
    unless logged_in?
      flash[:alert] = 'You must be logged in to access this page'
      redirect_to login_path
    end
  end
end
