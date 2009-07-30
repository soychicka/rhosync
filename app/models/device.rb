# == Schema Information
# Schema version: 20090624184104
#
# Table name: devices
#
#  id           :integer(4)    not null, primary key
#  created_at   :datetime      
#  updated_at   :datetime      
#  device_type  :string(255)   
#  carrier      :string(255)   
#  manufacturer :string(255)   
#  model        :string(255)   
#  user_id      :integer(4)    
#  pin          :string(255)   
#  host         :string(255)   
#  serverport   :string(255)   
#  deviceport   :string(255)   
#

class Device < ActiveRecord::Base
  #  belongs_to :source  DON'T NEED THIS NOW. Can just say that devices belong to users
  belongs_to :user
  set_inheritance_column "device_type"
  
  def ping(callback_url,message=nil,vibrate=nil,badge=nil)  # this should never get hit
    raise "Base device class notify.  Should never hit this!"
  end
end
