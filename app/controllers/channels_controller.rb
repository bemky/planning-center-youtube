class ChannelsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @channels = youtube_service.channels
  end
  
  private
  
  def youtube_service
    @youtube_service ||= YoutubeService.new(current_user)
  end
end