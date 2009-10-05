# == Schema Information
# Schema version: 20090921184016
#
# Table name: object_values
#
#  id                :integer(4)    not null, primary key
#  source_id         :integer(4)    
#  object            :string(255)   
#  attrib            :string(255)   
#  value             :text          
#  pending_id        :integer(4)    
#  update_type       :string(255)   
#  user_id           :integer(4)    
#  created_at        :datetime      
#  updated_at        :datetime      
#  blob_file_name    :string(255)   
#  blob_content_type :string(255)   
#  blob_file_size    :integer(4)    
#  attrib_type       :string(255)   
#
   
require 'digest/sha1'

class ObjectValue < ActiveRecord::Base
  RESERVED_ATTRIB_NAMES = ["attrib_type", "id"] 
  belongs_to :source
  has_many :clients
  has_many :client_temp_objects
  has_attached_file :blob
  
  attr_accessor :db_operation, :oo
  
  validates_presence_of :attrib, :value
  
  def before_save
    if self.pending_id.nil?
      self.pending_id = hash_from_data(self.attrib,self.object,self.update_type,self.source_id,self.user_id,self.value)  
    else
      logger.warn "Record exists: " + self.inspect.to_s
    end
  end 
  
  def validate
    RESERVED_ATTRIB_NAMES.each do |invalid_name|
      errors.add(:attrib, "'#{invalid_name}' is not a valid attribute name") if attrib == invalid_name  
    end
  end

  def hash_from_data(attrib=nil,object=nil,update_type=nil,source_id=nil,user_id=nil,value=nil,random=nil)
    self.class.hash_from_data(attrib,object,update_type,source_id,user_id,value,random)
  end
  
  def self.hash_from_data(attrib=nil,object=nil,update_type=nil,source_id=nil,user_id=nil,value=nil,random=nil)
   string = "#{object}#{attrib}#{update_type}#{source_id}#{user_id}#{value}#{random}"
   res = Digest::SHA1.hexdigest string
   return  res[0..14].hex
  end
  
  def self.record_object_value(oav)
    ovdata = ObjectValue.find(:first, :conditions => {:object=>oav[:object], :attrib=>oav[:attrib], 
                                  :user_id=>oav[:user_id], :source_id=>oav[:source_id]})
    if ovdata
      ovdata.delete
    end
    
    ObjectValue.create(:object=>oav[:object], :attrib=>oav[:attrib],
      :user_id=>oav[:user_id], :source_id=>oav[:source_id], :value=> oav[:value], :update_type=>"query")
  end
  
  # Returns the OAV list for a given user/source
  # If conditions are provided, return a subset of OAVs
  def self.get_sql_by_conditions(utype,source_id,user_id=nil,conditions=nil,by_source=nil)
    sql = ""
    by_source_condition = "and ov.source_id=#{source_id}" if by_source
    user_str = user_id.nil? ? '' : " and user_id=#{user_id}"
    if conditions
      counter = 0
      sql << "select * from object_values where object in "
      conditions.each do |key,val|
        sql << " (select object from object_values where (value like '#{val}%' 
                  and attrib='#{key}') 
                  #{by_source_condition}
                  and update_type='#{utype}' #{user_str}) "                
        sql <<  " and object in " if counter < conditions.length-1
        counter += 1
      end
    else
      sql << "select * from object_values where update_type='#{utype}' and source_id=#{source_id} #{user_str}"
    end
    sql << " order by object,attrib"
    sql
  end
end
