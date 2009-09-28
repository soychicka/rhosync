class SourceAdapterException < RuntimeError; end

# raise this to cause client to be logged out during a sync
class SourceAdapterLoginException < SourceAdapterException; end

# raise these to trigger rhosync sending an error to the client
class SourceAdapterServerTimeoutException < SourceAdapterException; end

class SourceAdapterServerErrorException < SourceAdapterException; end

class SourceAdapter
  attr_accessor :client
  attr_accessor :qparms
  attr_accessor :session
    
  def initialize(source=nil,credential=nil)
    @source = source.nil? ? self : source
  end

  def login; end
  
  def query; end
  
  # this base class sync method now expects a (NEW IN 1.2) "Hash of Hashes generic results" structure.
  # specifically "generic results" is a hash of hashes.  The outer hash is the set of objects (keyed by the ID)
  # the inner hash is the set of attributes
  # you can choose to use or not use the parent class sync in your own RhoSync source adapters
  def sync
    return if result_attribute_nil? or result_empty?

    if running_mysql?
      Rails.logger.debug "MySQL optimized sync"
      sql="INSERT INTO object_values(pending_id,source_id,object,attrib,value,user_id,attrib_type) VALUES"
      inserted_objects = 0
      inserted_object_values = 0
      
      @result.keys.each do |objkey|
        obj=@result[objkey]   
        if below_objects_limit?( inserted_objects )
          attrib_type = obj['attrib_type']
          obj.keys.each do |attrkey|
            unless invalid_attribute_key?(attrkey) or obj[attrkey].blank?
              obj[attrkey]=obj[attrkey].to_s if obj[attrkey].is_a? Fixnum
              obj[attrkey] = repeat_single_quotes_for_sql_string_value( obj[attrkey] )
              # allow override of source_id here
              src_id = obj[:source_id]
              src_id ||= @source.id
              pending_id = ObjectValue.hash_from_data(attrkey,objkey,nil,src_id,current_user_id,obj[attrkey])          
              sql << "(" + pending_id.to_s + "," + src_id.to_s + ",'" + objkey + "','" + attrkey + "','" + obj[attrkey] + "'," + current_user_id.to_s + (attrib_type ? ",'#{attrib_type}'" : ',NULL') + "),"
              
              if sql.size > MAX_SQL_STATEMENT_LENGTH  # this should not really be necessary. its just for safety. we've seen errors with very large statements
                sql.chop!
                ActiveRecord::Base.connection.execute sql
                sql="INSERT INTO object_values(pending_id,source_id,object,attrib,value,user_id,attrib_type) VALUES"
              end
              inserted_object_values += 1
            end
          end
          inserted_objects += 1
        end
      end
      sql.chop!
      
      if inserted_object_values != 0 
        ActiveRecord::Base.connection.execute sql
      end
      
    else  # sqlite and others dont support multiple row inserts from one SQL statement
      Rails.logger.debug "Sync for SQLite and other databases"
      
      inserted_objects = 0
      
      @result.keys.each do |objkey|
        obj=@result[objkey]
        
        if below_objects_limit?(inserted_objects)
          attrib_type = obj['attrib_type']
          
          obj.keys.each do |attrkey|
            unless invalid_attribute_key?(attrkey) or obj[attrkey].blank?
              obj[attrkey] = repeat_single_quotes_for_sql_string_value( obj[attrkey] )

              # allow override of source_id here
              src_id = obj[:source_id]
              src_id ||= @source.id
              
              sql="INSERT INTO object_values(pending_id,source_id,object,attrib,value,user_id,attrib_type) VALUES"
              pending_id = ObjectValue.hash_from_data(attrkey,objkey,nil,src_id,current_user_id,obj[attrkey])          
              sql << "(" + pending_id.to_s + "," + src_id.to_s + ",'" + objkey + "','" + attrkey + "','" + obj[attrkey] + "'," + current_user_id.to_s + (attrib_type ? ",'#{attrib_type}'" : ',NULL') + ")"
              ActiveRecord::Base.connection.execute sql
            end  
          end # for all keys in hash
          
          inserted_objects += 1
        end # limit number of objects
      end                
    end
  end
  
  def create(name_value_list)
  end

  def update(name_value_list); end

  def delete(name_value_list); end

  def logoff
  end
  
  # only implement this if you want RhoSync to install a callback into your backend
  #def set_callback(notify_urL)
  #  
  #end
  
  
  MSG_NO_OBJECTS = "No objects returned from query"
  MSG_NIL_RESULT_ATTRIB = "You might have expected a synchronization but the @result attribute was 'nil'"
  
  
  #################################################
  private 
  
  MAX_SQL_STATEMENT_LENGTH = 64000
  
  def repeat_single_quotes_for_sql_string_value(string)
    string.gsub(/\'/,"''")
  end
  
  # TODO: Move to ObjectValue class where it belongs
  def invalid_attribute_key?(attrkey)
    attrkey.blank? or attrkey=="id" or attrkey=="attrib_type"
  end
  
  def below_objects_limit?(inserted_objects)
    @source.limit.blank? or inserted_objects < @source.limit.to_i
  end
  
  def result_empty?
    if @result.empty?
      Rails.logger.debug MSG_NO_OBJECTS
      true
    else
      false
    end
  end

  def result_attribute_nil?
    unless @result
      Rails.logger.warn MSG_NIL_RESULT_ATTRIB
      true
    else
      false
    end
  end
  
  def running_mysql?
    config =Rails::Configuration.new
    config.database_configuration[RAILS_ENV]["adapter"]=="mysql"
  end
  
  def current_user_id
    @cached_user_id ||= (@source.current_user.nil? ? 'NULL' : @source.current_user.id)
  end
end
