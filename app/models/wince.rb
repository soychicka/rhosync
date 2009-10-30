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

class Wince < Client
  def ping(callback_url,message=nil,vibrate=nil,badge=nil,sound=nil)  # do an Wince-based push to the specified 
  end
end
