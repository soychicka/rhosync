require 'uuidtools'

class Client < ActiveRecord::Base
  set_primary_key :client_id
  belongs_to :user
  has_many :client_maps, :dependent => :destroy
  has_many :object_values, :through => :client_maps
  set_inheritance_column "device_type"
  
  attr_accessible :client_id, :last_sync_token, :updated_at
  
  def initialize(params=nil)
    super
    self.client_id = UUID.random_create.to_s unless self.client_id
  end
  
  def ping(callback_url,message=nil,vibrate=nil,badge=nil)  # this should never get hit
    raise "Base client class notify.  Should never hit this!"
  end
end