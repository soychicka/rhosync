# == Schema Information
# Schema version: 20090624184104
#
# Table name: memberships
#
#  id         :integer(4)    not null, primary key
#  app_id     :integer(4)    
#  user_id    :integer(4)    
#  created_at :datetime      
#  updated_at :datetime      
#

class Membership < ActiveRecord::Base
  belongs_to :app
  belongs_to :user
  has_one :credential
end
