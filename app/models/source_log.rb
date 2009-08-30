# == Schema Information
# Schema version: 20090624184104
#
# Table name: source_logs
#
#  id         :integer(4)    not null, primary key
#  error      :string(255)   
#  message    :string(255)   
#  time       :integer(4)    
#  operation  :string(255)   
#  source_id  :integer(4)    
#  created_at :datetime      
#  updated_at :datetime      
#  timing     :float         
#

class SourceLog < ActiveRecord::Base
  belongs_to :source
end
