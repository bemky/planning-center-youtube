module PlanningCenter
  class ServiceTypesController < ApplicationController
    before_action :authenticate_user!
    
    def index
      Rails.logger.info("Fetching Planning Center service types")
      begin
        @service_types = PlanningCenter::ServiceType.all
        Rails.logger.info("Successfully retrieved #{@service_types.size} service types")
      rescue StandardError => e
        Rails.logger.error("Error in service_types#index: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        @service_types = []
        flash.now[:alert] = "Error loading service types. Please try again later."
      end
    end
    
    def show
      Rails.logger.info("Fetching Planning Center service type: #{params[:id]}")
      
      begin
        service = PlanningCenter::ApiService.new
        data = service.service_type(params[:id])
        
        Rails.logger.info("Service type data retrieved, creating model")
        @service_type = PlanningCenter::ServiceType.from_api(data)
        
        if @service_type
          Rails.logger.info("Fetching plans for service type #{@service_type.name}")
          @plans = @service_type.plans(filter: 'future', per_page: 10)
          Rails.logger.info("Retrieved #{@plans.size} plans")
        else
          Rails.logger.error("Failed to create ServiceType model from API data")
          flash[:alert] = "Service type not found"
          redirect_to planning_center_service_types_path
        end
      rescue StandardError => e
        Rails.logger.error("Error in service_types#show: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        flash[:alert] = "Error loading service type: #{e.message}"
        redirect_to planning_center_service_types_path
      end
    end
  end
end