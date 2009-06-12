class SourceAdapter
  attr_accessor :client
  attr_accessor :qparms
  
  def initialize(source=nil,credential=nil)
    @source = source.nil? ? self : source
  end

  def login
  end

  
  def query
  end
  
  # this base class sync method now expects a (NEW IN 1.2) "Hash of Hashes generic results" structure.
  # specifically "generic results" is a hash of hashes.  The outer hash is the set of objects (keyed by the ID)
  # the inner hash is the set of attributes
  # you can choose to use or not use the parent class sync in your own RhoSync source adapters
  def sync
    if @result.size>0 
      if @source.credential.nil?
        user_id='NULL'
      else
        user_id=@source.current_user.id
      end
      config =Rails::Configuration.new
      if config.database_configuration[RAILS_ENV]["adapter"]=="mysql"
        max_sql_statement=2048
        p "MySQL optimized sync"
        sql="INSERT INTO object_values(id,pending_id,source_id,object,attrib,value,user_id) VALUES"
        count=0
        @result.keys.each do |objkey|
          obj=@result[objkey]   
          if @source.limit.blank? or count < @source.limit.to_i # if there's a limit on objects see if we've exceeded it          
            obj.keys.each do |attrkey|
              unless attrkey.blank? or obj[attrkey].blank?   
                obj[attrkey]=obj[attrkey].gsub(/\'/,"''")  # handle apostrophes
                ovid=ObjectValue.hash_from_data(attrkey,objkey,nil,@source.id,user_id,obj[attrkey],rand)
                pending_id = ObjectValue.hash_from_data(attrkey,objkey,nil,@source.id,user_id,obj[attrkey])          
                sql << "(" + ovid.to_s + "," + pending_id.to_s + "," + @source.id.to_s + ",'" + objkey + "','" + attrkey + "','" + obj[attrkey] + "'," + user_id.to_s + "),"
              end
            end
            count+=1
          end
        end
        sql.chop!
        ActiveRecord::Base.connection.execute sql
      else  # sqlite and others dont support multiple row inserts from one SQL statement
        p "Sync for SQLite and other databases"
        count=0
        @result.keys.each do |objkey|
          obj=@result[objkey]
          if @source.limit.blank? or count < @source.limit.to_i    # if there's a limit on objects see if we've exceeded it 
            obj.keys.each do |attrkey|
              unless attrkey.blank? or obj[attrkey].blank?  
                obj[attrkey]=obj[attrkey].gsub(/\'/,"''")        
                sql="INSERT INTO object_values(id,pending_id,source_id,object,attrib,value,user_id) VALUES"
                ovid=ObjectValue.hash_from_data(attrkey,objkey,nil,@source.id,user_id,obj[attrkey],rand)
                pending_id = ObjectValue.hash_from_data(attrkey,objkey,nil,@source.id,user_id,obj[attrkey])          
                sql << "(" + ovid.to_s + "," + pending_id.to_s + "," + @source.id.to_s + ",'" + objkey + "','" + attrkey + "','" + obj[attrkey] + "'," + user_id.to_s + ")"
                ActiveRecord::Base.connection.execute sql
              end  
            end # for all keys in hash
            count+=1
          end # limit number of objects
        end                
      end

    else
      p "No objects returned from query"
    end
  end

  def create(name_value_list)
  end

  def update(name_value_list)
  end

  def delete(name_value_list)
  end

  def logoff
  end
  
  def set_callback(notify_urL)
    
  end
end