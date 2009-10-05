# == Schema Information
# Schema version: 20090921184016
#
# Table name: clients
#
#  client_id       :string(36)    primary key
#  session         :string(255)   
#  created_at      :datetime      
#  updated_at      :datetime      
#  user_id         :integer(4)    
#  last_sync_token :string(255)   
#  device_type     :string(255)   
#  carrier         :string(255)   
#  manufacturer    :string(255)   
#  model           :string(255)   
#  pin             :string(255)   
#  host            :string(255)   
#  serverport      :string(255)   
#  deviceport      :string(255)   
#

require 'uuidtools'

class Client < ActiveRecord::Base
  set_primary_key :client_id
  belongs_to :user
  has_many :client_maps
  has_many :object_values, :through => :client_maps
  has_many :client_temp_objects, :dependent => :destroy
  set_inheritance_column "device_type"
  
  attr_accessible :client_id, 
                  :last_sync_token, 
                  :updated_at, 
                  :carrier, 
                  :device_type, 
                  :deviceport, 
                  :manufacturer, 
                  :serverport, 
                  :host, 
                  :model,
                  :pin
  
  def initialize(params=nil)
    super
    self.client_id = UUIDTools::UUID.random_create.to_s unless self.client_id
  end

  def before_destroy
    ClientMap.delete_all(:client_id => self.client_id)
  end

  def reset
    ActiveRecord::Base.transaction do
      ClientMap.delete_all(:client_id => self.client_id)
      ClientTempObject.delete_all(:client_id => self.client_id)
      self.last_sync_token=nil
      self.save
    end
  end
  
  def ping(callback_url,message=nil,vibrate=nil,badge=nil,sound=nil)  # this should never get hit
    raise "Base client class notify.  Should never hit this!"
  end
end

