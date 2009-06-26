class Device < ActiveRecord::Base
  #  belongs_to :source  DON'T NEED THIS NOW. Can just say that devices belong to users
  belongs_to :user
  set_inheritance_column "device_type"
  
  def ping(callback_url,message=nil,vibrate=nil)  # this should never get hit
    raise "Base device class notify.  Should never hit this!"
  end
end
