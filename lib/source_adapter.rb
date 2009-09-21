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
    unless @result
      Rails.logger.warn "You might have expected a synchronization but the @result attribute was 'nil'"
      return
    end
    
    if @result.size>0 
      if @source.current_user.nil?
        user_id='NULL'
      else
        user_id=@source.current_user.id
      end
      config =Rails::Configuration.new
      if config.database_configuration[RAILS_ENV]["adapter"]=="mysql"
        max_sql_statement=64000
        Rails.logger.debug "MySQL optimized sync"
        sql="INSERT INTO object_values(pending_id,source_id,object,attrib,value,user_id,attrib_type) VALUES"
        count=0
        @result.keys.each do |objkey|
          obj=@result[objkey]   
          if @source.limit.blank? or count < @source.limit.to_i # if there's a limit on objects see if we've exceeded it          
            attrib_type = obj['attrib_type']
            obj.keys.each do |attrkey|
              unless attrkey.blank? or obj[attrkey].blank? or attrkey=="id" or attrkey=="attrib_type"
                obj[attrkey]=obj[attrkey].to_s if obj[attrkey].is_a? Fixnum
                obj[attrkey]=obj[attrkey].gsub(/\'/,"''")  # handle apostrophes
                # allow override of source_id here
                src_id = obj[:source_id]
                src_id ||= @source.id
                pending_id = ObjectValue.hash_from_data(attrkey,objkey,nil,src_id,user_id,obj[attrkey])          
                sql << "(" + pending_id.to_s + "," + src_id.to_s + ",'" + objkey + "','" + attrkey + "','" + obj[attrkey] + "'," + user_id.to_s + (attrib_type ? ",'#{attrib_type}'" : ',NULL') + "),"
                
                if sql.size > max_sql_statement  # this should not really be necessary. its just for safety. we've seen errors with very large statements
                  sql.chop!
                  ActiveRecord::Base.connection.execute sql
                  sql="INSERT INTO object_values(pending_id,source_id,object,attrib,value,user_id,attrib_type) VALUES"
                end
              end
            end
            count+=1
          end
        end
        sql.chop!
        ActiveRecord::Base.connection.execute sql
      else  # sqlite and others dont support multiple row inserts from one SQL statement
        Rails.logger.debug "Sync for SQLite and other databases"
        count=0
        @result.keys.each do |objkey|
          obj=@result[objkey]
          if @source.limit.blank? or count < @source.limit.to_i    # if there's a limit on objects see if we've exceeded it 
            attrib_type = obj['attrib_type']
            obj.keys.each do |attrkey|
              unless attrkey.blank? or obj[attrkey].blank?  or attrkey=="id"
                obj[attrkey]=obj[attrkey].gsub(/\'/,"''")  # handle apostrophes
                # allow override of source_id here
                src_id = obj[:source_id]
                src_id ||= @source.id
                sql="INSERT INTO object_values(pending_id,source_id,object,attrib,value,user_id,attrib_type) VALUES"
                pending_id = ObjectValue.hash_from_data(attrkey,objkey,nil,src_id,user_id,obj[attrkey])          
                sql << "(" + pending_id.to_s + "," + src_id.to_s + ",'" + objkey + "','" + attrkey + "','" + obj[attrkey] + "'," + user_id.to_s + (attrib_type ? ",'#{attrib_type}'" : ',NULL') + ")"
                ActiveRecord::Base.connection.execute sql
              end  
            end # for all keys in hash
            count+=1
          end # limit number of objects
        end                
      end

    else
      Rails.logger.debug "No objects returned from query"
    end
  end

  def create(name_value_list); end

  def update(name_value_list); end

  def delete(name_value_list); end

  def logoff; end
end