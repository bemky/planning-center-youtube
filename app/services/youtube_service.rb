require 'google/apis/youtube_v3'

class YoutubeService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def client
    @client ||= begin
      client = Google::Apis::YoutubeV3::YouTubeService.new
      client.authorization = authorization
      client
    end
  end

  def channels
    response = client.list_channels('snippet,contentDetails', mine: true)
    response.items || []
  end

  def videos(channel_id, max_results = 50)
    response = client.list_searches('snippet', channel_id: channel_id, type: 'video', max_results: max_results, order: 'date')
    videos = response.items || []
    
    # Get full video details
    if videos.any?
      video_ids = videos.map(&:id).map(&:video_id)
      client.list_videos('snippet,contentDetails,statistics,status', id: video_ids.join(','))&.items || []
    else
      []
    end
  end

  def update_video(video_id, title: nil, description: nil, privacy_status: nil)
    begin
      # Get the video with snippet part first
      snippet_video = client.list_videos('snippet', id: video_id).items.first
      return nil unless snippet_video
      
      # Make snippet updates
      if title || description
        # Clone the snippet for update
        snippet = snippet_video.snippet.dup
        snippet.title = title if title
        snippet.description = description if description
        
        # Create update video object with only the snippet
        update_video = Google::Apis::YoutubeV3::Video.new(
          id: video_id,
          snippet: snippet
        )
        
        # Update just the snippet
        client.update_video('snippet', update_video)
      end
      
      # Handle privacy status separately if provided
      if privacy_status
        begin
          # Get the video with status part
          status_video = client.list_videos('status', id: video_id).items.first
          
          # Create update video object with only the status
          update_video = Google::Apis::YoutubeV3::Video.new(
            id: video_id,
            status: Google::Apis::YoutubeV3::VideoStatus.new(
              privacy_status: privacy_status
            )
          )
          
          # Update just the status
          client.update_video('status', update_video)
        rescue => e
          Rails.logger.error("Error updating video privacy: #{e.message}")
        end
      end
      
      return true
    rescue => e
      Rails.logger.error("Error updating video: #{e.message}")
      Rails.logger.debug("Stack trace: #{e.backtrace.join("\n")}")
      return nil
    end
  end
  
  # Toggle video privacy between public and private
  def toggle_privacy(video_id)
    begin
      # Get the current status
      video = client.list_videos('status', id: video_id).items.first
      return nil unless video
      
      # Toggle privacy status
      current_status = video.status.privacy_status
      new_status = (current_status == 'public') ? 'private' : 'public'
      
      # Create a new video object with just the status
      update_video = Google::Apis::YoutubeV3::Video.new(
        id: video_id,
        status: Google::Apis::YoutubeV3::VideoStatus.new(
          privacy_status: new_status
        )
      )
      
      # Update just the status
      result = client.update_video('status', update_video)
      
      # Return the new status
      return result ? new_status : nil
    rescue => e
      Rails.logger.error("Error toggling privacy: #{e.message}")
      Rails.logger.debug("Stack trace: #{e.backtrace.join("\n")}")
      return nil
    end
  end
  
  # Find or create a playlist with the given title
  def find_or_create_playlist(title, description = nil)
    return nil unless title.present?
    
    # Check if playlist already exists
    existing_playlist = find_playlist_by_title(title)
    return existing_playlist if existing_playlist
    
    # Create new playlist
    playlist = Google::Apis::YoutubeV3::Playlist.new(
      snippet: Google::Apis::YoutubeV3::PlaylistSnippet.new(
        title: title,
        description: description || "Created by Planning Center YouTube integration"
      ),
      status: Google::Apis::YoutubeV3::PlaylistStatus.new(
        privacy_status: 'public'
      )
    )
    
    begin
      # The YouTube API expects 'part' not 'parts'
      result = client.insert_playlist('snippet,status', playlist)
      return result.id
    rescue => e
      Rails.logger.error("Error creating playlist: #{e.message}")
      Rails.logger.debug("Playlist creation error details: #{e.inspect}")
      
      # Try with just snippet if status causes issues
      begin
        playlist = Google::Apis::YoutubeV3::Playlist.new(
          snippet: Google::Apis::YoutubeV3::PlaylistSnippet.new(
            title: title,
            description: description || "Created by Planning Center YouTube integration"
          )
        )
        result = client.insert_playlist('snippet', playlist)
        return result.id
      rescue => e2
        Rails.logger.error("Second attempt at playlist creation failed: #{e2.message}")
        return nil
      end
    end
  end
  
  # Find a playlist by title
  def find_playlist_by_title(title)
    begin
      # Get all playlists for the channel
      response = client.list_playlists('snippet', mine: true, max_results: 50)
      playlists = response.items || []
      
      # Find playlist with matching title
      matching_playlist = playlists.find { |p| p.snippet.title == title }
      return matching_playlist&.id
    rescue => e
      Rails.logger.error("Error finding playlist: #{e.message}")
      return nil
    end
  end
  
  # Add a video to a playlist
  def add_video_to_playlist(playlist_id, video_id)
    return false unless playlist_id.present? && video_id.present?
    
    # Check if video is already in the playlist
    if video_in_playlist?(playlist_id, video_id)
      Rails.logger.info("Video #{video_id} is already in playlist #{playlist_id}")
      return true
    end
    
    # Create playlist item
    playlist_item = Google::Apis::YoutubeV3::PlaylistItem.new(
      snippet: Google::Apis::YoutubeV3::PlaylistItemSnippet.new(
        playlist_id: playlist_id,
        resource_id: Google::Apis::YoutubeV3::ResourceId.new(
          kind: 'youtube#video',
          video_id: video_id
        )
      )
    )
    
    begin
      client.insert_playlist_item('snippet', playlist_item)
      Rails.logger.info("Successfully added video #{video_id} to playlist #{playlist_id}")
      return true
    rescue => e
      Rails.logger.error("Error adding video to playlist: #{e.message}")
      Rails.logger.debug("Full error details: #{e.inspect}")
      
      # Retry with a slightly modified approach if needed
      if e.message.include?("unexpectedPart")
        begin
          # Try with a simpler object structure
          playlist_item = Google::Apis::YoutubeV3::PlaylistItem.new(
            snippet: Google::Apis::YoutubeV3::PlaylistItemSnippet.new(
              playlist_id: playlist_id,
              resource_id: {
                kind: 'youtube#video',
                videoId: video_id
              }
            )
          )
          client.insert_playlist_item('snippet', playlist_item)
          Rails.logger.info("Successfully added video on second attempt")
          return true
        rescue => e2
          Rails.logger.error("Second attempt to add video failed: #{e2.message}")
          return false
        end
      end
      
      return false
    end
  end
  
  # Check if a video is already in a playlist
  def video_in_playlist?(playlist_id, video_id)
    begin
      response = client.list_playlist_items('snippet', playlist_id: playlist_id, max_results: 50)
      items = response.items || []
      
      # Handle both possible property names (video_id or videoId)
      return items.any? do |item| 
        if item.snippet.resource_id.respond_to?(:video_id)
          item.snippet.resource_id.video_id == video_id
        elsif item.snippet.resource_id.respond_to?(:videoId)
          item.snippet.resource_id.videoId == video_id
        else
          # If neither method exists, check if it's a hash
          rid = item.snippet.resource_id
          if rid.is_a?(Hash)
            rid['videoId'] == video_id || rid['video_id'] == video_id
          else
            false
          end
        end
      end
    rescue => e
      Rails.logger.error("Error checking if video is in playlist: #{e.message}")
      Rails.logger.debug("Full error details: #{e.inspect}")
      # Assume it's not in the playlist on error
      return false
    end
  end
  
  # Upload a custom thumbnail for a video
  # The image_url must be publicly accessible
  def set_custom_thumbnail(video_id, image_url)
    return false unless video_id.present? && image_url.present?
    
    begin
      # Download the image from the URL
      image_tempfile = download_image(image_url)
      return false unless image_tempfile
      
      # Create a thumbnail object
      thumbnail = Google::Apis::YoutubeV3::Thumbnail.new
      
      # Set the video thumbnail
      thumbnail = client.set_thumbnail(video_id, upload_source: image_tempfile.path, content_type: 'image/jpeg')
      
      # Clean up the temporary file
      image_tempfile.close
      image_tempfile.unlink
      
      return true
    rescue StandardError => e
      Rails.logger.error("Error setting custom thumbnail: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return false
    end
  end
  
  # Download an image from a URL to a temporary file
  # Resize if necessary to meet YouTube's 2MB limit
  def download_image(url)
    require 'open-uri'
    require 'tempfile'
    require 'mini_magick'
    
    begin
      # Create a tempfile for the image
      tempfile = Tempfile.new(['thumbnail', '.jpg'])
      tempfile.binmode
      
      # Download the image
      image_data = URI.open(url).read
      tempfile.write(image_data)
      tempfile.rewind
      
      # Check file size (2MB = 2,097,152 bytes)
      max_size = 2 * 1024 * 1024
      
      if File.size(tempfile.path) > max_size
        Rails.logger.info("Image is larger than 2MB (#{File.size(tempfile.path)} bytes), resizing...")
        
        # Process with MiniMagick
        image = MiniMagick::Image.open(tempfile.path)
        
        # Try different approaches to get under 2MB
        
        # First try: quality reduction to 80%
        image.quality(80)
        image.write(tempfile.path)
        tempfile.rewind
        
        if File.size(tempfile.path) <= max_size
          Rails.logger.info("Successfully reduced image to #{File.size(tempfile.path)} bytes with 80% quality")
          return tempfile
        end
        
        # Second try: quality reduction to 70%
        image = MiniMagick::Image.open(tempfile.path)
        image.quality(70)
        image.write(tempfile.path)
        tempfile.rewind
        
        if File.size(tempfile.path) <= max_size
          Rails.logger.info("Successfully reduced image to #{File.size(tempfile.path)} bytes with 70% quality")
          return tempfile
        end
        
        # Third try: quality reduction to 60% plus resize to 80% dimensions
        image = MiniMagick::Image.open(tempfile.path)
        image.quality(60)
        image.resize("80%")
        image.write(tempfile.path)
        tempfile.rewind
        
        if File.size(tempfile.path) <= max_size
          Rails.logger.info("Successfully reduced image to #{File.size(tempfile.path)} bytes with 60% quality and 80% dimensions")
          return tempfile
        end
        
        # Last resort: resize to 50% of original dimensions with 60% quality
        image = MiniMagick::Image.open(tempfile.path)
        image.quality(60)
        image.resize("50%")
        image.write(tempfile.path)
        tempfile.rewind
        
        Rails.logger.info("Final image size: #{File.size(tempfile.path)} bytes with 60% quality and 50% dimensions")
        return tempfile
        
      else
        # File is already under 2MB, return as is
        Rails.logger.info("Image is already under 2MB (#{File.size(tempfile.path)} bytes), using as is")
        return tempfile
      end
    rescue StandardError => e
      Rails.logger.error("Error processing image: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return nil
    end
  end

  private

  def authorization
    auth = Google::Auth::UserRefreshCredentials.new(
      client_id: Rails.application.credentials.google_client_id,
      client_secret: Rails.application.credentials.google_client_secret,
      scope: ['https://www.googleapis.com/auth/youtube'],
      access_token: user.token,
      refresh_token: user.refresh_token,
      expires_at: user.token_expires_at
    )
    
    # Refresh the token if it's expired
    if user.token_expired?
      auth.refresh!
      # Update the user's token
      user.token = auth.access_token
      user.token_expires_at = auth.expires_at
    end
    
    auth
  end
end