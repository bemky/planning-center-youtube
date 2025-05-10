# Explicitly require the OAuth provider
require 'omniauth-google-oauth2'

# Reset OmniAuth config first to ensure clean state
OmniAuth.config.full_host = nil

# Configure OmniAuth global options
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.logger = Rails.logger

# Set up the middleware
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    Rails.application.credentials.google_client_id,
    Rails.application.credentials.google_client_secret,
    {
      name: 'google_oauth2',
      scope: 'email, profile, https://www.googleapis.com/auth/youtube',
      prompt: 'select_account',
      access_type: 'offline',
      include_granted_scopes: true
    }
end

# For debugging - print out the available strategies
Rails.application.config.after_initialize do
  puts "OmniAuth strategies: #{OmniAuth::Strategies.constants.inspect}"
end