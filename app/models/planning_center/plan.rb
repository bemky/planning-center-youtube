require 'pco_api'

module PlanningCenter
  class Plan
    include ActiveModel::Model
    include ActiveModel::Attributes
    
    attribute :id, :string
    attribute :series_title, :string
    attribute :series_id, :string
    attribute :title, :string
    attribute :date, :string
    attribute :sort_date, :string
    attribute :created_at, :string
    attribute :updated_at, :string
    attribute :service_type_id, :string
    attribute :service_type_name, :string
    attribute :date_proximity, :integer
    
    # Initialize from API data
    def self.from_api(data)
      return nil unless data && data['attributes'] && data['relationships']
      
      service_type_id = nil
      if data['relationships']['service_type'] && 
         data['relationships']['service_type']['data']
        service_type_id = data['relationships']['service_type']['data']['id']
      end
      
      series_id = nil
      if data['relationships']['series'] && 
         data['relationships']['series']['data']
        series_id = data['relationships']['series']['data']['id']
      end
      
      new(
        id: data['id'],
        series_title: data['attributes']['series_title'],
        series_id: series_id,
        title: data['attributes']['title'],
        date: data['attributes']['dates'],
        sort_date: data['attributes']['sort_date'],
        created_at: data['attributes']['created_at'],
        updated_at: data['attributes']['updated_at'],
        service_type_id: service_type_id
      )
    end
    
    # Get items for this plan
    def items
      service = PlanningCenter::ApiService.new
      begin
        items_data = service.items(service_type_id, id)
        items_data.map { |data| PlanningCenter::Item.from_api(data) }.compact
      rescue StandardError => e
        Rails.logger.error("Error fetching items: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end
    
    # Get series artwork URL if available
    def series_artwork_url
      return nil unless series_id.present?
      
      service = PlanningCenter::ApiService.new
      begin
        series_data = service.series(series_id)
        return nil unless series_data && series_data['attributes']
        
        # Try to get the artwork URL from the series data
        series_data.dig('attributes', 'artwork_original') ||
        series_data.dig('attributes', 'artwork_original_url') || 
        series_data.dig('attributes', 'artwork_url') || 
        series_data.dig('attributes', 'artwork_medium_url') ||
        series_data.dig('attributes', 'artwork_thumbnail_url')
      rescue StandardError => e
        Rails.logger.error("Error fetching series artwork: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        nil
      end
    end
  end
end