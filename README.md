# Planning Center YouTube Manager

A Rails application that allows users to authenticate with Google, view their YouTube channels, list their live videos, and edit video titles and descriptions.

## Features

- Google OAuth authentication
- View your YouTube channels
- List videos for each channel
- Edit video titles and descriptions directly from the app
- Changes sync back to YouTube via the YouTube API
- Integration with Planning Center Services API
- View service types and upcoming plans

## Requirements

- Ruby 3.4.1
- Rails 7.1.5+
- Google API credentials (OAuth 2.0)

## Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/planning-center-youtube.git
cd planning-center-youtube
```

2. Install dependencies:
```bash
bundle install
```

3. Add your API credentials to Rails credentials:
```bash
rails credentials:edit
```

Add the following to your credentials file:
```yaml
# Google OAuth credentials
google_client_id: your_google_client_id
google_client_secret: your_google_client_secret

# Planning Center API credentials
planning_center_id: your_planning_center_app_id
planning_center_secret: your_planning_center_app_secret
```

4. Set up Google API credentials:
   - Go to the [Google Developers Console](https://console.developers.google.com/)
   - Create a new project
   - Enable the YouTube Data API v3
   - Create OAuth 2.0 credentials
   - Add the following redirect URIs:
     - `http://localhost:3000/auth/google_oauth2/callback` (for local development)
     - If using ngrok or similar services: `https://your-ngrok-domain.ngrok-free.app/auth/google_oauth2/callback`
   - Save your Client ID and Client Secret
   
   **Note**: When using a service like ngrok, make sure to add the redirect URI with your specific ngrok domain to the Google OAuth 2.0 credentials.

5. Start the Rails server:
```bash
./start.sh
# or
rails server
```

6. Open your browser:
   - For local development: navigate to `http://localhost:3000`
   - If using ngrok: navigate to your ngrok URL (e.g., `https://your-ngrok-domain.ngrok-free.app`)

## Using with ngrok

To expose your application to the internet (useful for testing OAuth flows):

1. Install ngrok: [https://ngrok.com/download](https://ngrok.com/download)

2. Run ngrok pointing to your Rails server port:
```bash
ngrok http 3000
```

3. Copy the HTTPS URL provided by ngrok (e.g., `https://07ba-24-245-153-192.ngrok-free.app`)

4. Add this URL with the callback path to your Google OAuth 2.0 credentials:
   - Go to the [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to "APIs & Services" > "Credentials"
   - Edit your OAuth 2.0 Client ID
   - Add a new Authorized redirect URI: `https://your-ngrok-domain.ngrok-free.app/auth/google_oauth2/callback`
   - Save your changes

5. Access your application via the ngrok URL

## Application Structure

- **Models**: `User` (in-memory model without database)
- **Controllers**: `ApplicationController`, `HomeController`, `SessionsController`, `ChannelsController`, `VideosController`
- **Services**: `YoutubeService` (handles interactions with YouTube API)
- **Views**: Home page, channels index, videos index, video edit page

## License

MIT
