# == Schema Information
# Schema version: 20090624184104
#
# Table name: source_notifies
#
#  id         :integer(4)    not null, primary key
#  source_id  :integer(4)    
#  user_id    :integer(4)    
#  created_at :datetime      
#  updated_at :datetime      
#

class SourceNotify < ActiveRecord::Base
  belongs_to :user
  belongs_to :source
end
