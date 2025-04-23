Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Rails.application.credentials.google_client_id, Rails.application.credentials.google_client_secret, {
    scope: 'email, profile, https://www.googleapis.com/auth/youtube',
    prompt: 'select_account',
    access_type: 'offline',
    include_granted_scopes: true,
    redirect_uri: lambda { |env| 
      host = env['HTTP_HOST']
      protocol = env['rack.url_scheme']
      "#{protocol}://#{host}/auth/google_oauth2/callback"
    }
  }
end

OmniAuth.config.allowed_request_methods = [:post, :get]