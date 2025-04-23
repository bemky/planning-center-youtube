require 'pco_api'

module PlanningCenter
  class ApiService
    # Initialize with the global PCO API instance
    def initialize
      @api = $pco_api
    end

    # Get all service types
    def service_types
      begin
        response = @api.services.v2.service_types.get
        response["data"]
      rescue StandardError => e
        Rails.logger.error("Error fetching service types: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end

    # Get service type by ID
    def service_type(id)
      begin
        response = @api.services.v2.service_types[id].get
        response["data"]
      rescue StandardError => e
        Rails.logger.error("Error fetching service type: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        nil
      end
    end

    # Get plans for a service type
    def plans(service_type_id, params = {})
      begin
        response = @api.services.v2.service_types[service_type_id].plans.get(params)
        response["data"]
      rescue StandardError => e
        Rails.logger.error("Error fetching plans: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end

    # Get items for a plan
    def items(service_type_id, plan_id, params = {})
      begin
        response = @api.services.v2.service_types[service_type_id].plans[plan_id].items.get(params)
        response["data"]
      rescue StandardError => e
        Rails.logger.error("Error fetching items: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end
    
    # Get series details
    def series(series_id, params = {})
      begin
        response = @api.services.v2.series[series_id].get(params)
        response["data"]
      rescue StandardError => e
        Rails.logger.error("Error fetching series: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        nil
      end
    end

    # Get all organizations
    def organizations
      begin
        response = @api.people.v2.organizations.get
        response["data"]
      rescue StandardError => e
        Rails.logger.error("Error fetching organizations: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end

    # Error handling helper
    def handle_error(error)
      case error
      when ::PCO::API::Errors::ClientError
        { error: "Client Error: #{error.message}", status: error.status }
      when ::PCO::API::Errors::ServerError
        { error: "Server Error: #{error.message}", status: error.status }
      when ::PCO::API::Errors::ConnectionError
        { error: "Connection Error: #{error.message}" }
      else
        { error: "Unknown Error: #{error.message}" }
      end
    end
  end
end