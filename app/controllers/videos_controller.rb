class VideosController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @channel_id = params[:channel_id]
    @videos = youtube_service.videos(@channel_id)
  end
  
  def edit
    @video_id = params[:id]
    
    # Fetch extended information about the video
    # First get the basic video information
    @video = youtube_service.client.list_videos('snippet,liveStreamingDetails,contentDetails,statistics', id: @video_id).items.first
    # Find matching Planning Center plans
    if @video
      # Get the video creation date - which is not directly available from the YouTube API
      # We need to make additional requests to get the closest approximation
      
      # Initialize our date variable
      video_date = nil
      date_source = nil
      
      # Try to get upload information - this is different from the published date and closer to creation
      begin
        # If the video is part of an uploaded playlist, that can give us a more accurate date
        uploaded_at = @video.to_h.dig(:live_streaming_details, :actual_start_time)
        if uploaded_at
          video_date = Date.parse(uploaded_at)
          date_source = "stream date"
          Rails.logger.info("Using video upload date for matching: #{video_date}")
        end
      rescue => e
        Rails.logger.warn("Could not fetch upload date: #{e.message}")
      end
      
      # If we still don't have a date, fall back to published date
      if video_date.nil? && @video.snippet.published_at
        video_date = Date.parse(@video.snippet.published_at)
        date_source = "publish date"
        Rails.logger.info("Falling back to video published date: #{video_date}")
      end
      
      # Store the date source for the view
      @video_date_source = date_source
      @video_date = video_date
      
      if video_date
        Rails.logger.info("Finding Planning Center plans matching video date: #{video_date}")
        @matching_plans = find_matching_planning_center_plans(video_date)
      end
    end
  end
  
  # Try to fetch the upload date which is closer to creation date than published date
  def fetch_video_uploaded_date(video_id)
    # Try to get the video upload timestamp from snippets
    begin
      # First approach: try getting video details with fileDetails scope
      # (Note: This may not work with the current scope permissions)
      file_details = youtube_service.client.list_videos('fileDetails', id: video_id).items.first
      if file_details&.file_details&.file_creation_date
        return file_details.file_details.file_creation_date
      end
    rescue => e
      Rails.logger.warn("Could not fetch file details: #{e.message}")
    end
    
    # Second approach: Check if video is in an "uploads" playlist 
    # and get the date it was added to the playlist
    begin
      # Get the channel for this video
      channel_response = youtube_service.client.list_videos('snippet', id: video_id).items.first
      if channel_response && channel_response.snippet.channel_id
        channel_id = channel_response.snippet.channel_id
        
        # Get the uploads playlist for this channel
        channels_response = youtube_service.client.list_channels('contentDetails', id: channel_id)
        uploads_playlist_id = channels_response.items.first.content_details.related_playlists.uploads
        
        # Find this video in the uploads playlist
        playlist_items = youtube_service.client.list_playlist_items(
          'snippet', 
          playlist_id: uploads_playlist_id,
          video_id: video_id
        )
        
        if playlist_items.items.any?
          # Return the time the video was added to the uploads playlist
          # This is often very close to the actual upload time
          return playlist_items.items.first.snippet.published_at
        end
      end
    rescue => e
      Rails.logger.warn("Could not fetch upload playlist date: #{e.message}")
    end
    
    # If all else fails, return nil and let the caller fall back to publish date
    return nil
  end
  
  # Find Planning Center plans that match the video date
  def find_matching_planning_center_plans(video_date)
    begin
      # Get all service types
      planning_center_service = PlanningCenter::ApiService.new
      service_types = planning_center_service.service_types
      
      # For each service type, find plans with EXACT date match
      matching_plans = []
      
      # Format date for exact match
      exact_date = video_date.strftime('%B %-d, %Y')
      Rails.logger.info("Looking for exact date match: #{exact_date}")
      
      service_types.each do |service_type_data|
        service_type = PlanningCenter::ServiceType.from_api(service_type_data)
        next unless service_type
        
        # Get plans for this service type with exact date match
        plans_data = planning_center_service.plans(
          service_type.id,
          order: '-sort_date',
          include: 'series'
        ).select {|p| p["attributes"]["dates"].include?(exact_date)}
        
        Rails.logger.info("Found #{plans_data.length} plans for service type #{service_type.name} on date #{exact_date}")
        
        plans_data.each do |plan_data|
          plan = PlanningCenter::Plan.from_api(plan_data)
          next unless plan
          
          # Add the service type name to the plan for display purposes
          plan.service_type_name = service_type.name
          
          # Set date proximity to 0 since we're only looking for exact matches
          plan.date_proximity = 0
          matching_plans << plan
        end
      end
      
      # Sort plans by service type name for consistent display
      matching_plans.sort_by { |plan| plan.service_type_name }
    rescue StandardError => e
      Rails.logger.error("Error finding matching plans: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      []
    end
  end
  
  def update
    @video_id = params[:id]
    
    if youtube_service.update_video(@video_id, title: params[:video][:title], description: params[:video][:description])
      redirect_to channel_videos_path(params[:channel_id]), notice: 'Video updated successfully!'
    else
      flash.now[:alert] = 'Failed to update video'
      @video = youtube_service.client.list_videos('snippet', id: @video_id).items.first
      render :edit
    end
  end
  
  def toggle_privacy
    @video_id = params[:id]
    
    new_status = youtube_service.toggle_privacy(@video_id)
    
    respond_to do |format|
      if new_status
        format.html { redirect_to channel_videos_path(params[:channel_id]), notice: "Video privacy set to #{new_status}" }
        format.json { render json: { success: true, video_id: @video_id, privacy_status: new_status } }
      else
        format.html { redirect_to channel_videos_path(params[:channel_id]), alert: "Failed to update video privacy" }
        format.json { render json: { success: false, error: "Failed to update privacy" }, status: :unprocessable_entity }
      end
    end
  end
  
  def sync_from_plan
    @video_id = params[:id]
    @plan_id = params[:plan_id]
    
    # Get the plan details
    planning_center_service = PlanningCenter::ApiService.new
    plan_data = planning_center_service.plans(params[:service_type_id], where: {id: @plan_id}).first
    return render json: { error: "Plan not found" }, status: :not_found unless plan_data
    
    plan = PlanningCenter::Plan.from_api(plan_data)
    return render json: { error: "Invalid plan data" }, status: :unprocessable_entity unless plan
    
    # Get plan items to find the sermon
    plan_items = planning_center_service.items(params[:service_type_id], @plan_id)
    sermon_item = plan_items.find { |item| item.dig("attributes", "title").include?("Sermon") }
    
    # Extract scripture reference using regex
    scripture_reference = nil
    if sermon_item
      matches = sermon_item.dig("attributes", "title").match(/(?:\d\s)?\w[\w+\s]+\d+\:\d+\s?\-\s?\d+/)
      scripture_reference = matches[0] if matches
    end
    
    # Create the new title
    plan_title = plan.title.presence || "Sunday Worship"
    scripture_suffix = scripture_reference ? " (#{scripture_reference})" : ""
    
    # Only include series title if present
    new_title = if plan.series_title.present?
      "#{plan.series_title}: #{plan_title}#{scripture_suffix}"
    else
      "#{plan_title}#{scripture_suffix}"
    end
    
    # Get the sermon description if available
    new_description = nil
    if sermon_item && sermon_item.dig("attributes", "description").present?
      new_description = sermon_item.dig("attributes", "description")
    end
    
    # Update the video title and description
    update_result = youtube_service.update_video(@video_id, 
                                                title: new_title,
                                                description: new_description)
    
    # Try to set the thumbnail from series artwork if available
    thumbnail_updated = false
    thumbnail_message = nil
    
    if update_result && plan.series_id.present?
      # Get the series artwork URL
      artwork_url = plan.series_artwork_url
      
      if artwork_url.present?
        # Set the video thumbnail
        if youtube_service.set_custom_thumbnail(@video_id, artwork_url)
          thumbnail_updated = true
          thumbnail_message = "Series artwork set as video thumbnail."
        else
          thumbnail_message = "Failed to set series artwork as thumbnail."
        end
      else
        thumbnail_message = "No series artwork available."
      end
    end
    
    # Create or find a playlist for the series and add the video to it
    playlist_added = false
    playlist_message = nil
    
    if update_result && plan.series_title.present?
      # Create a playlist for the series if it doesn't exist
      playlist_id = youtube_service.find_or_create_playlist(plan.series_title, "Videos from the #{plan.series_title} series")
      
      if playlist_id
        # Add the video to the playlist
        if youtube_service.add_video_to_playlist(playlist_id, @video_id)
          playlist_added = true
          playlist_message = "Video added to '#{plan.series_title}' playlist."
        else
          playlist_message = "Failed to add video to '#{plan.series_title}' playlist."
        end
      else
        playlist_message = "Failed to create playlist for series."
      end
    end
    
    if update_result
      # Prepare success messages
      message = "Video updated successfully!"
      if thumbnail_updated
        message += " " + thumbnail_message
      end
      if playlist_added
        message += " " + playlist_message
      end
      
      render json: { 
        success: true, 
        new_title: new_title,
        new_description: new_description,
        thumbnail_updated: thumbnail_updated,
        thumbnail_message: thumbnail_message,
        playlist_added: playlist_added,
        playlist_message: playlist_message,
        message: message
      }
    else
      render json: { 
        success: false, 
        message: "Failed to update video"
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def youtube_service
    @youtube_service ||= YoutubeService.new(current_user)
  end
end