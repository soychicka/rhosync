# == Schema Information
# Schema version: 20090624184104
#
# Table name: credentials
#
#  id            :integer(4)    not null, primary key
#  login         :string(255)   
#  password      :string(255)   
#  token         :string(255)   
#  membership_id :integer(4)    
#  created_at    :datetime      
#  updated_at    :datetime      
#  url           :string(255)   
#

class Credential < ActiveRecord::Base
  belongs_to :membership
  has_one :user, :through=>:membership
end
  
