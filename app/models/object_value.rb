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
   
class ObjectValue < ActiveRecord::Base
  belongs_to :source
  has_many :clients
  has_many :client_temp_objects
  has_attached_file :blob
  
  attr_accessor :db_operation, :oo
  
  def before_save
    if self.pending_id.nil?
      self.pending_id = hash_from_data(self.attrib,self.object,self.update_type,self.source_id,self.user_id,self.value)  
    else
      logger.warn "Record exists: " + self.inspect.to_s
    end  
  end

  def hash_from_data(attrib=nil,object=nil,update_type=nil,source_id=nil,user_id=nil,value=nil,random=nil)
    self.class.hash_from_data(attrib,object,update_type,source_id,user_id,value,random)
  end
  
  def self.hash_from_data(attrib=nil,object=nil,update_type=nil,source_id=nil,user_id=nil,value=nil,random=nil)
    res = user_id.nil? ? 0 : (user_id & 0xff)
    res <<= 8
    res |= (attrib.hash & 0xff)
    res <<= 8
    res |= (source_id & 0xff)
    res <<= 16
    res |= (object.hash & 0xffff)
    res <<= 16
    res |= (value.hash & 0xffff)
    
    if [1752717433503793, 1752720129523761, 1752716365398065].include?(res)
      logger.debug "*************************\n\nPOSSIBLE DUPLICATE\n\n********************\n"
      logger.debug "attrib=#{attrib}\nobject=#{object}\nupdate_type=#{update_type.inspect.to_s}\nsource_id=#{source_id}\nuser_id=#{user_id}\nvalue=#{value}"
    end
    
    res
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
