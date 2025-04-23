require 'pco_api'

module PlanningCenter
  class Item
    include ActiveModel::Model
    include ActiveModel::Attributes
    
    attribute :id, :string
    attribute :title, :string
    attribute :sequence, :integer
    attribute :item_type, :string
    attribute :description, :string
    attribute :length, :integer
    attribute :plan_id, :string
    
    # Initialize from API data
    def self.from_api(data)
      return nil unless data && data['attributes'] && data['relationships']
      
      plan_id = nil
      if data['relationships']['plan'] && 
         data['relationships']['plan']['data']
        plan_id = data['relationships']['plan']['data']['id']
      end
      
      new(
        id: data['id'],
        title: data['attributes']['title'],
        sequence: data['attributes']['sequence'],
        item_type: data['attributes']['item_type'],
        description: data['attributes']['description'],
        length: data['attributes']['length'],
        plan_id: plan_id
      )
    end
  end
end