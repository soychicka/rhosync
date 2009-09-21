# == Schema Information
# Schema version: 20090921184016
#
# Table name: client_temp_objects
#
#  id            :integer(4)    not null, primary key
#  client_id     :string(255)   
#  objectid      :string(255)   
#  temp_objectid :string(255)   
#  created_at    :datetime      
#  updated_at    :datetime      
#

class ClientTempObject < ActiveRecord::Base
  belongs_to :client
  belongs_to :object_value
end
