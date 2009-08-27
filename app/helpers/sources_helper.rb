module SourcesHelper
  
  def slog(e,msg,source_id=self.id,operation=nil,timing=nil)
    begin
      l=SourceLog.new
      l.source_id=source_id
      l.error=e.inspect.to_s if not e.nil?
      l.error||=""
      l.message=msg
      l.operation=operation
      l.timing=timing
      l.save
    rescue Exception=>e
      logger.debug "Failed to save source log message: " + e
    end
  end
  
  def tlog(start,operation,source_id)
    diff=(Time.new-start)
    slog(nil,"Timing: "+diff.to_s+" seconds",source_id,operation,diff)
  end


  # determines if the logged in users is a subscriber of the current app or 
  # admin of the current app
  def check_access(app)
    logger.debug "Checking access for user "+@current_user.login
    matches_login=app.users.select{ |u| u.login==@current_user.login}
    matches_login << app.administrations.select { |a| a and a.user and a.user.login==@current_user.login } # let the administrators of the app in as well
    if !(app.anonymous==1) and (matches_login.nil? or matches_login.size == 0)
      logger.info  "App is not anonymous and user was not found in subscriber list"
      logger.info "User: " + current_user.login + " not allowed access."
      username = current_user.login
      username ||= "unknown"
      result=nil
    end
    result=@current_user
  end
  
  def needs_refresh
    result=nil
    # refresh if there are any updates to come
    # INDEX: SHOULD USE BY_SOURCE_USER_TYPE 
    count_updates = "select count(*) from object_values where update_type!='query' and source_id="+id.to_s
    (count_updates << " and user_id="+ credential.user.id.to_s) if credential# if there is a credential then just do delete and update based upon the records with that credential  
    if (ObjectValue.count_by_sql count_updates ) > 0
      p "Refreshing source #{name} #{id} because there are some non-query object values"
      return true
    end

    # refresh if there is no data
    # INDEX: SHOULD USE BY_SOURCE_USER_TYPE
    count_query_objs="select count(*) from object_values where update_type='query' and source_id="+id.to_s
    (count_query_objs << " and user_id="+ credential.user.id.to_s) if credential# if there is a credential then just do delete and update based upon the records with that credential  
    if (ObjectValue.count_by_sql count_query_objs ) <= 0
      p "Refreshing source #{name} #{id} because there is no data stored in object values"
      return true
    end
    
    # provided there is data....
    # allow -1 to mean dont ever poll
    return false if -1==self.pollinterval
    
    # allow 0 to mean always poll
    return true if 0==self.pollinterval
    
    # refresh is the data is old
    self.pollinterval||=300 # 5 minute default if there's no pollinterval or its a bad value
    if !self.refreshtime or ((Time.new - self.refreshtime)>pollinterval)
      p "Refreshing source #{name} #{id}  because the data is old: #{self.refreshtime}"
      return true
    end
    
    false  # return true of false (nil)
  end
  
  # presence or absence of credential determines whether we are using a "per user sandbox" or not
  def clear_pending_records(credential)
    delete_cmd= "(update_type is null) and source_id="+id.to_s
    (delete_cmd << " and user_id="+ credential.user.id.to_s) if credential # if there is a credential then just do delete and update based upon the records with that credential
    begin
      start=Time.new
      ObjectValue.delete_all delete_cmd
      tlog(start,"delete",self.id)
    rescue Exception=>e
      slog(e, "Failed to delete existing records ",self.id)
    end
  end
  
  # presence or absence of credential determines whether we are using a "per user sandbox" or not
  def remove_dupe_pendings(credential)
    pendings_cmd = "select id,pending_id,object,attrib,value from object_values where update_type is null and source_id="+id.to_s
    (pendings_cmd << " and user_id="+ credential.user.id.to_s) if credential# if there is a credential then just do delete and update based upon the records with that credential  
    pendings_cmd << " order by pending_id"
    objs=ObjectValue.find_by_sql pendings_cmd
    prev=nil
    objs.each do |obj|  # remove dupes
      if (prev and (obj.pending_id==prev.pending_id))
        dupemsg="Incrementing duplicate pending ID: #{obj.pending_id.to_s} for OAV: #{obj.object.to_s},#{obj.attrib},#{obj.value}."
        p dupemsg
        logger.info dupemsg
        obj.pending_id=obj.pending_id+1  
        ObjectValue.delete(prev.id)
      end
      prev=obj
    end
  end
  
  # this function performs pending to final convert one at a time and is robust to failures to to do a pending to final for a single object
  # now only used by dosearch method on sources controller
  def update_pendings(credential,check_existing=nil)
    conditions="source_id=#{id}"
    conditions << " and user_id=#{credential.user.id}" if credential
    objs=ObjectValue.find :all, :conditions=>conditions, :order=> :pending_id
    objs.each do |obj|  
      begin
        pending_to_query="update object_values set update_type='query',id=pending_id where id="+obj.id.to_s+" and update_type is null"
        #pending_to_query=pending_to_query + " and pending_id not in (select id from object_values where update_type='query')" if check_existing
        p "Finalizing record: #{pending_to_query}"
        ActiveRecord::Base.connection.execute(pending_to_query)
      rescue Exception => e
        slog(e,"Failed to finalize object value (due to duplicate) for object "+obj.id.to_s,id)
      end
    end   
  end

  # presence or absence of credential determines whether we are using a "per user sandbox" or not
  def finalize_query_records(credential,source_id=nil)
    source_id||=id
    # first delete the existing query records
    ActiveRecord::Base.transaction do
      delete_cmd = "(update_type is not null and update_type !='qparms') and source_id="+source_id.to_s
      (delete_cmd << " and user_id="+ credential.user.id.to_s) if credential # if there is a credential then just do delete and update based upon the records with that credential
      ObjectValue.delete_all delete_cmd
      remove_dupe_pendings(credential)
      pending_to_query="update object_values set update_type='query',id=pending_id where update_type is null and source_id="+source_id.to_s
      (pending_to_query << " and user_id=" + credential.user.id.to_s) if credential
      p "Finalizing with #{pending_to_query}"
      ActiveRecord::Base.connection.execute(pending_to_query)
      # this function performs pending to final convert one at a time and is robust to failures to to do a pending to final for a single object
      #update_pendings(credential,nil) # if ever called here doesnt need to check for existing
    end
    self.refreshtime=Time.new if defined? self.refreshtime # timestamp    
    self.save
  end

  def finalize_query_records(credential,source_id=nil)
    source_id||=id
    # first delete the existing query records
    ActiveRecord::Base.transaction do

      remove_dupe_pendings(credential)
      pending_to_query="update object_values set update_type='query',id=pending_id where update_type is null and source_id="+source_id.to_s
      (pending_to_query << " and user_id=" + credential.user.id.to_s) if credential
      p "Finalizing with #{pending_to_query}"
      ActiveRecord::Base.connection.execute(pending_to_query)
      # this function performs pending to final convert one at a time and is robust to failures to to do a pending to final for a single object
      #update_pendings
    end
    self.refreshtime=Time.new if defined? self.refreshtime # timestamp    
    self.save
  end


  # helper function to come up with the string used for the name_value_list
  # name_value_list =  [ { "name" => "name", "value" => "rhomobile" },
  #                     { "name" => "industry", "value" => "software" } ]
  def make_name_value_list(hash)
    if hash and hash.keys.size>0
      result="["
      hash.keys.each do |x|
        result << ("{'name' => '"+ x +"', 'value' => '" + hash[x] + "'},") if x and x.size>0 and hash[x]
      end
      result=result[0...result.size-1]  # chop off last comma
      result += "]"
    end
  end
    
  def process_update_type(utype)
    start=Time.new  # start timing the operation
    objs=ObjectValue.find_by_sql("select distinct(object) as object,blob_file_name,blob_content_type,blob_file_size from object_values where update_type='"+ utype +"'and source_id="+id.to_s)
    if objs # check that we got some object values back
      objs.each do |x|
        logger.debug "Object returned is: " + x.inspect.to_s
        if x.object  
          objvals=ObjectValue.find_all_by_object_and_update_type(x.object,utype)  # this has all the attribute value pairs now
          attrvalues={}
          attrvalues["id"]=x.object if utype!='create' # setting the ID allows it be an update or delete
          blob_file=x.blob_file_name
          objvals.each do |y|
            attrvalues[y.attrib]=y.value
          end
          # now attrvalues has the attribute values needed for the create,update,delete call
          nvlist=make_name_value_list(attrvalues)
          if source_adapter
            name_value_list=eval(nvlist)
            params="(name_value_list"+ (x.blob_file_name ? ",x.blob)" : ")")
            cmd="source_adapter." +utype +params
            p "Executing" + cmd
            eval cmd
          end
        else
          msg="Missing object property on object value: " + x.inspect.to_s
          logger.info msg
        end
      end
    else # got no object values back
      msg "Failed to retrieve object values for " + utype
      slog(nil,msg)
    end
    tlog(start,utype,self.id) # log the time to perform the particular type of operation
  end
  
  # for query parameters (update type of qparms) they get cleared on subsequent calls just for a given user (or credentials)
  def cleanup_update_type(utype,user_id=nil)
    cleanup_cmd="select distinct(object) as object from object_values where update_type='"+ utype +"'and source_id="+id.to_s
    (cleanup_cmd << " and user_id="+ user_id.to_s) if user_id# if there is a user_id then just do delete and update based upon the records with that credential  
    objs=ObjectValue.find_by_sql(cleanup_cmd)
    
    objs.each do |x| 
      if x.object
        objvals=ObjectValue.find_all_by_object_and_update_type(x.object,utype)  # this has all the attribute value pairs now
        objvals.each do |y|
          y.destroy
        end
      else
        msg="Missing object property on object value: " + x.inspect.to_s
        p msg
        slog(nil,msg)
      end 
    end   
  end
  
  # grab out all ObjectValues of updatetype="Create" with object named "qparms" 
  # for a specific user (user_id) and source (id)
  # put those together into a hash where each attrib is the key and each value is the value
  # return nil if there are no such objects
  def qparms_from_object(user_id)
    qparms=nil
    attrs=ObjectValue.find_by_sql("select * from object_values where object='qparms' and source_id="+id.to_s+" and user_id="+user_id.to_s)
    if attrs
      cleanup_update_type('qparms',user_id)
      qparms={}
      attrs.each do |x|
        qparms[x.attrib]=x.value
        if x.update_type == 'create'
          x.update_attribute('update_type', 'qparms') 
          x.save
        end
      end
    end
    qparms
  end
  
  def setup_client(client_id)
    # setup client & user association if it doesn't exist
    if client_id and client_id != 'client_id'
      @client = Client.find_by_client_id(client_id)
      if @client.nil?
        @client = Client.new
        @client.client_id = client_id
      end
      @client.user ||= current_user
      @client.save
    end
    @client
  end

  # check if there have been any changes on the client
  # used to determine whether to ping client about changes
  def check_for_changes_for_client(client)
    have_changes=nil
    objs_to_return = []
    page_size = 100 # make it small just to do the check
    user_condition="= #{current_user.id}" if current_user and current_user.id
    user_condition ||= "is NULL"
    # Setup the join conditions
    object_value_join_conditions = "from object_values ov left join client_maps cm on \
                                    ov.id = cm.object_value_id and \
                                    cm.client_id = '#{client.id}'"
    object_value_conditions = "#{object_value_join_conditions} \
                               where ov.update_type = 'query' and \
                                 ov.source_id = #{id} and \
                                 ov.user_id #{user_condition} and \
                                 cm.object_value_id is NULL order by ov.object limit #{page_size}"                  
    object_value_query = "select * #{object_value_conditions}"
    objs=ClientMap.check_insert_objects(object_value_query,client.id)  # are there any objects to insert for this client
    if objs and objs.size>0
      have_changes=true
    end
    objs=ClientMap.check_delete_objects(client.id) # are there any objects to delete for this client
    if objs and objs.size>0
      have_changes=true
    end
    have_changes
  end
  
  # creates an object_value list for a given client
  # based on that client's client_map records
  # and the current state of the object_values table
  # since we do a delete_all in rhosync refresh, 
  # only delete and insert are required
  def process_objects_for_client(source,client,token,ack_token,resend_token,p_size=nil,first_request=false,ov_table=nil)
    
    # default page size of 10000
    page_size = p_size.nil? ? 10000 : p_size.to_i
    last_sync_time = Time.now
    objs_to_return = []
    user_condition="= #{current_user.id}" if current_user and current_user.id
    user_condition ||= "is NULL"
    
    ov_table||="object_values"  # will use a temp table (e.g. "subset_values") if we have a search with offset and limit
    
    # Setup the join conditions
    object_value_join_conditions = "from #{ov_table} ov left join client_maps cm on \
                                    ov.id = cm.object_value_id and \
                                    cm.client_id = '#{client.id}'"
    object_value_conditions = "#{object_value_join_conditions} \
                               where ov.update_type = 'query' and \
                                 ov.source_id = #{source.id} and \
                                 ov.user_id #{user_condition} and \
                                 cm.object_value_id is NULL order by ov.object limit #{page_size}"                  
    object_value_query = "select * #{object_value_conditions}"
    
    # setup fields to insert in client_maps table
    object_insert_query = "select '#{client.id}' as a,id,'insert','#{token}' #{object_value_conditions}"
                    
    # if we're resending the token, quickly return the results (inserts + deletes)
    if resend_token
      logger.debug "[sources_helper] resending token, resend_token: #{resend_token.inspect}"
      objs_to_return = ClientMap.get_delete_objs_by_token_status(client.id)
      client.update_attributes({:updated_at => last_sync_time, :last_sync_token => resend_token})
      objs_to_return.concat( ClientMap.get_insert_objs_by_token_status(object_value_join_conditions,client.id,resend_token) )
    else
      logger.debug "[sources_helper] ack_token: #{ack_token.inspect}, using new token: #{token.inspect}"
      
      # mark acknowledged token so we don't send it again
      ClientMap.mark_objs_by_ack_token(ack_token) if ack_token and ack_token.length > 0
      
      # find delete records
      objs_to_return.concat( ClientMap.get_delete_objs_for_client(token,page_size,client.id) )

      # find + save insert records
      objs_to_insert = ObjectValue.find_by_sql object_value_query
      ClientMap.insert_new_client_maps(object_insert_query)
      objs_to_insert.collect! {|x| x.db_operation = 'insert'; x}

      # Update the last updated time for this client
      # to track the last sync time
      client.update_attribute(:updated_at, last_sync_time)
      objs_to_return.concat(objs_to_insert)
      
      if token and objs_to_return.length > 0
        client.update_attribute(:last_sync_token, token)
      else
        client.update_attribute(:last_sync_token, nil)
      end
    end
    objs_to_return
  end
end