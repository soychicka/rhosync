# == Schema Information
# Schema version: 20090624184104
#
# Table name: object_values
#
#  id                :integer(4)    not null, primary key
#  source_id         :integer(4)    
#  object            :string(255)   
#  attrib            :string(255)   
#  value             :text(255)     
#  pending_id        :integer(4)    
#  update_type       :string(255)   
#  user_id           :integer(4)    
#  created_at        :datetime      
#  updated_at        :datetime      
#  blob_file_name    :string(255)   
#  blob_content_type :string(255)   
#  blob_file_size    :integer(4)    
#

class ObjectValue < ActiveRecord::Base
  set_primary_key :id
  belongs_to :source
  has_many :clients, :through => :client_maps
  has_many :client_maps
  has_attached_file :blob
  
  attr_accessor :db_operation
  
  def get_id
    self.id
  end
  
  def before_save
    if self.pending_id.nil?
      self.id=self.class.hash_from_data(self.attrib,self.object,self.update_type,self.source_id,self.user_id,self.value,rand.to_s)
      self.pending_id=self.class.hash_from_data(self.attrib,self.object,self.update_type,self.source_id,self.user_id,self.value)  
      p "Object Value ID: " + self.id.to_s
    else
      p "Record exists: " + self.inspect.to_s
    end  
  end

  def hash_from_data(attrib=nil,object=nil,update_type=nil,source_id=nil,user_id=nil,value=nil,random=nil)
    self.class.hash_from_data(attrib,object,update_type,source_id,user_id,value,random)
  end
  
  def self.hash_from_data(attrib=nil,object=nil,update_type=nil,source_id=nil,user_id=nil,value=nil,random=nil)
    "#{object}#{attrib}#{update_type}#{source_id}#{user_id}#{value}#{random}".hash.to_i.abs
  end
end
