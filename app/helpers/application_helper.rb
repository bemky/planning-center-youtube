module ApplicationHelper
  # Format ISO 8601 duration (PT1H30M15S) to readable format (1:30:15)
  def format_youtube_duration(iso8601_duration)
    return '' unless iso8601_duration
    
    # Remove the PT from the beginning
    duration = iso8601_duration.gsub(/^PT/, '')
    
    # Extract hours, minutes, seconds
    hours = duration.match(/(\d+)H/)&.captures&.first.to_i
    minutes = duration.match(/(\d+)M/)&.captures&.first.to_i
    seconds = duration.match(/(\d+)S/)&.captures&.first.to_i
    
    # Format based on whether we have hours or not
    if hours > 0
      format("%d:%02d:%02d", hours, minutes, seconds)
    else
      format("%d:%02d", minutes, seconds)
    end
  end
end
