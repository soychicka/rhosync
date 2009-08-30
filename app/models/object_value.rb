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
class ObjectValue < ActiveRecord::Base
  belongs_to :source
  has_many :clients
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
  
  
  # Returns the OAV list for a given user/source
  # If conditions are provided, return a subset of OAVs
  def self.search_by_conditions(utype,source_id,user_id=nil,conditions=nil)
    sql = ""
    user_str = user_id.nil? ? '' : " and user_id = #{user_id}"
    if conditions
      counter = 0
      sql << "select * from object_values where object in "
      conditions.each do |key,val|
        sql << " (select object from object_values where (value like '#{val}%' 
                  and attrib = '#{key}') and source_id = #{source_id} 
                  and update_type = '#{utype}' #{user_str}) "
                  
        sql <<  " and object in " if counter < conditions.length-1
        counter += 1
      end
      sql << " order by object,attrib"
    else
      sql << "select * from object_values where update_type='#{utype}' and source_id=#{source_id} #{user_str}"
      sql << " order by object"
    end
    puts "sql: #{sql.inspect}"
    ObjectValue.find_by_sql sql
  end
end
