# == Schema Information
# Schema version: 20090921184016
#
# Table name: administrations
#
#  id         :integer(4)    not null, primary key
#  app_id     :integer(4)    
#  user_id    :integer(4)    
#  created_at :datetime      
#  updated_at :datetime      
#

class Administration < ActiveRecord::Base
  belongs_to :app
  belongs_to :user
end
