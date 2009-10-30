# == Schema Information
# Schema version: 20090921184016
#
# Table name: configurations
#
#  id         :integer(4)    not null, primary key
#  app_id     :integer(4)    
#  name       :string(255)   
#  value      :string(255)   
#  created_at :datetime      
#  updated_at :datetime      
#

class Configuration < ActiveRecord::Base
  belongs_to :app

end
