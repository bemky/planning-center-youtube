class SessionsController < ApplicationController
  def new
    redirect_to '/auth/google_oauth2'
  end

  def create
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)
    session[:user] = user.to_session
    redirect_to root_path, notice: 'Successfully signed in!'
  end

  def destroy
    session[:user] = nil
    redirect_to root_path, notice: 'Signed out!'
  end

  def failure
    redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
  end
end