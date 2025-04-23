require 'pco_api'

module PlanningCenter
  class ServiceType
    include ActiveModel::Model
    include ActiveModel::Attributes
    
    attribute :id, :string
    attribute :name, :string
    attribute :frequency, :string
    attribute :sequence, :integer
    attribute :last_plan_from, :string
    attribute :permalink, :string
    attribute :date_format, :string
    attribute :time_preference, :string
    
    # Initialize from API data
    def self.from_api(data)
      return nil unless data && data['attributes']
      
      new(
        id: data['id'],
        name: data['attributes']['name'],
        frequency: data['attributes']['frequency'],
        sequence: data['attributes']['sequence'],
        last_plan_from: data['attributes']['last_plan_from'],
        permalink: data['attributes']['permalink'],
        date_format: data['attributes']['date_format'],
        time_preference: data['attributes']['time_preference']
      )
    end
    
    # Get all service types
    def self.all
      service = PlanningCenter::ApiService.new
      begin
        service_types_data = service.service_types
        service_types_data.map { |data| from_api(data) }.compact
      rescue StandardError => e
        Rails.logger.error("Error fetching service types: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end
    
    # Get plans for this service type
    def plans(params = {})
      service = PlanningCenter::ApiService.new
      begin
        plans_data = service.plans(id, params)
        plans_data.map { |data| PlanningCenter::Plan.from_api(data) }.compact
      rescue StandardError => e
        Rails.logger.error("Error fetching plans: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end
  end
end