# == Schema Information
# Schema version: 20090624184104
#
# Table name: clients
#
#  client_id       :string(36)    primary key
#  session         :string(255)   
#  created_at      :datetime      
#  updated_at      :datetime      
#  user_id         :integer(4)    
#  last_sync_token :string(255)   
#

require 'uuidtools'

class Client < ActiveRecord::Base
  set_primary_key :client_id
  belongs_to :user
  has_many :client_maps
  has_many :object_values, :through => :client_maps
  attr_accessible :client_id, :last_sync_token, :updated_at
  
  def initialize(params=nil)
    super
    self.client_id = UUID.random_create.to_s unless self.client_id
  end
end
