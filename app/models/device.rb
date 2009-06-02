class Device < ActiveRecord::Base
  belongs_to :user
  
  def notify  # this should never get hit
    raise "Base device class notify.  Should never hit this!"
  end
end
