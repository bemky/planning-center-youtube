require 'pco_api'

# Initialize PCO::API with basic authentication
# The PCO::API gem doesn't use a configure block, but instead is initialized with credentials
# For reference: https://github.com/planningcenter/pco_api_ruby

# This is a global variable that will be accessible throughout the application
$pco_api = PCO::API.new(
  basic_auth_token: Rails.application.credentials.planning_center_id,
  basic_auth_secret: Rails.application.credentials.planning_center_secret
)