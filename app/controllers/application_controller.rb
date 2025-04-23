class ApplicationController < ActionController::Base
  helper_method :current_user, :user_signed_in?
  
  private
  
  def current_user
    @current_user ||= User.from_session(session[:user])
  end
  
  def user_signed_in?
    !!current_user
  end
  
  def authenticate_user!
    redirect_to root_path, alert: 'Please sign in to access this page.' unless user_signed_in?
  end
end
