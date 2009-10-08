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
    if @current_user
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
    end
    result=@current_user
  end

  def needs_refresh
    result=nil
    
    # check to make sure we are not running a paged query in the background
    command = "ruby script/runner ./jobs/page_query.rb #{credential.user.id} #{id} 0"
    jobs = Bj::Table::Job.find(:all, :conditions => ["command = ?", command])
		jobs.each do |job|
			if !job.finished?
				logger.info "pending paged query job detected, needs_refresh returning false"
				return false
			end
		end
    
    # refresh if there are any updates to come
    # INDEX: SHOULD USE BY_SOURCE_USER_TYPE
    count_updates = "select count(*) from object_values where update_type!='query' and source_id="+id.to_s
    (count_updates << " and user_id="+ credential.user.id.to_s) if credential# if there is a credential then just do delete and update based upon the records with that credential
    if (ObjectValue.count_by_sql count_updates ) > 0
      logger.info "Refreshing source #{name} #{id} because there are some non-query object values"
      return true
    end

    # refresh if there is no data
    # INDEX: SHOULD USE BY_SOURCE_USER_TYPE
    count_query_objs="select count(*) from object_values where update_type='query' and source_id="+id.to_s
    (count_query_objs << " and user_id="+ credential.user.id.to_s) if credential# if there is a credential then just do delete and update based upon the records with that credential
    if (ObjectValue.count_by_sql count_query_objs ) <= 0
      logger.info "Refreshing source #{name} #{id} because there is no data stored in object values"
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
      logger.info "Refreshing source #{name} #{id}  because the data is old: #{self.refreshtime}"
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
    objs.each do |obj| # remove dupes
      if (prev and (obj.pending_id==prev.pending_id))
        dupemsg="Deleting a duplicate pending ID: #{obj.pending_id.to_s} for OAV: #{obj.object.to_s},#{obj.attrib},#{obj.value})"
        logger.info dupemsg
        ObjectValue.delete(prev.id)
      end
      prev=obj
    end
  end

  # this function performs pending to final convert one at a time and is 
  # robust to failures to to do a pending to final for a single object
  def update_pendings(credential,check_existing=false)
    conditions="source_id=#{id}"
    conditions << " and user_id=#{credential.user.id}" if credential
    ActiveRecord::Base.transaction do
      objs=ObjectValue.find :all, :conditions=>conditions, :order=> :pending_id
      current_ids = ActiveRecord::Base.connection.select_values "select id from object_values where update_type='query'"
      objs.each do |obj|
        begin
          # if check_existing, look for existing query object-attribute and delete it before replacement
          if check_existing and current_ids.index(obj.pending_id.to_s) == nil
            existing = ObjectValue.find :first, :conditions => "object='#{obj.object}' and attrib='#{obj.attrib}' and 
                                                                update_type='query' and #{conditions}"
            existing.destroy if existing
            ActiveRecord::Base.connection.execute "update object_values set update_type='query',id=pending_id where
                                                   id="+obj.id.to_s+" and update_type is null"
            current_ids << obj.pending_id.to_s
          end
        rescue Exception => e
          slog(e,"Failed to finalize object value (due to duplicate) for object "+obj.id.to_s,id)
        end
      end
      self.refreshtime=Time.new
      # TODO: This is bad... These collided but we can't update them, so we delete for now.
      ActiveRecord::Base.connection.execute "delete from object_values where update_type is NULL and #{conditions}"
    end
  end

  # presence or absence of credential determines whether we are using a "per user sandbox" or not
  def finalize_query_records(credential, cleanup=true)
    # first delete the existing query records
    ActiveRecord::Base.transaction do
    	if cleanup
      	delete_cmd = "(update_type is not null and update_type !='qparms') and source_id="+id.to_s
      	(delete_cmd << " and user_id="+ credential.user.id.to_s) if credential # if there is a credential then just do delete and update based upon the records with that credential
      	ObjectValue.delete_all delete_cmd
    	end
      remove_dupe_pendings(credential)
      pending_to_query="update object_values set update_type='query',id=pending_id where update_type is null and source_id="+id.to_s
      (pending_to_query << " and user_id=" + credential.user.id.to_s) if credential
      ActiveRecord::Base.connection.execute(pending_to_query)
    end
    self.refreshtime=Time.new # timestamp
  end

  # helper function to come up with the string used for the name_value_list
  # name_value_list = [ { "name" => "name", "value" => "rhomobile" },
  # { "name" => "industry", "value" => "software" } ]
  def make_name_value_list(hash)
    if hash and hash.keys.size>0
      result="["
      hash.keys.each do |x|
        result << ("{'name' => '"+ x +"', 'value' => '" + hash[x] + "'},") if x and x.size>0 and hash[x]
      end
      result=result[0...result.size-1] if result.size > 1 # chop off last comma
      result += "]"
    end
  end

  def process_update_type(utype)
    start=Time.new # start timing the operation
    objs=ObjectValue.find_by_sql("select distinct(object) as object,blob_file_name,blob_content_type,blob_file_size 
                                  from object_values where update_type='"+ utype +"'and source_id="+id.to_s)
    res = nil
    if objs # check that we got some object values back
      objs.each do |x|
        logger.debug "Object returned is: " + x.inspect.to_s
        if x.object
          objvals=ObjectValue.find_all_by_object_and_update_type(x.object,utype) # this has all the attribute value pairs now
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
            logger.info "Executing" + cmd
            res = nil
            tmp_object = ClientTempObject.find_by_temp_objectid(x.object)
            begin
              res = eval cmd
              if res and res.is_a?(String) and tmp_object
                tmp_object.update_attributes(:objectid => res, :source_id => id)
              end
            rescue SourceAdapterException => sae
              if tmp_object
                tmp_object.update_attributes(:error => "#{sae.class}:#{sae}", :source_id => id)
              end
            end
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
    res
  end

  # for query parameters (update type of qparms) they get cleared on subsequent calls just for a given user (or credentials)
  def cleanup_update_type(utype,user_id=nil)
    cleanup_cmd="select distinct(object) as object from object_values where update_type='"+ utype +"'and source_id="+id.to_s
    (cleanup_cmd << " and user_id="+ user_id.to_s) if user_id# if there is a user_id then just do delete and update based upon the records with that credential
    objs=ObjectValue.find_by_sql(cleanup_cmd)

    objs.each do |x|
      if x.object
        objvals=ObjectValue.find_all_by_object_and_update_type(x.object,utype) # this has all the attribute value pairs now
        objvals.each do |y|
          y.destroy
        end
      else
        msg="Missing object property on object value: " + x.inspect.to_s
        logger.info msg
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

  def build_object_values(utype=nil,client_id=nil,ack_token=nil,p_size=nil,conditions=nil,by_source=nil)
    # if client_id is provided, return only relevant objects for that client
    if client_id
      @client = setup_client(client_id)
      @ack_token = ack_token
      @first_request=false
      @resend_token=nil

      # setup the conditions to handle the client request
      if @ack_token
        logger.debug "Received ack_token, ack_token: #{@ack_token.inspect}, new token: #{@token.inspect}"
      else
        # get last token if available, otherwise it's the first request
        # for a given source
        @resend_token=@client.last_sync_token
        if @resend_token.nil?
          @first_request=true
          logger.debug "First request for source"
        end
      end

      # generate new token for the next set of data
      @token=@resend_token ? @resend_token : get_new_token
      # get the list of objects
      # if this is a queued sync source and we are doing a refresh in the queue then wait for the queued sync to happen
      if @source.queuesync and @source.needs_refresh
        @object_values=[]
      else
        @object_values=process_objects_for_client(@source,@client,@token,@ack_token,@resend_token,p_size,@first_request,by_source)
      end
      # set token depending on records returned
      # if we sent zero records, we need to keep track so the client
      # doesn't receive the last page again
      @token=nil if @object_values.nil? or @object_values.length == 0

      logger.debug "Finished processing objects for client, token: #{@token.inspect}, last_sync_token: #{@client.last_sync_token.inspect}, object_values count: #{@object_values.length}"

      @total_count = ObjectValue.count_by_sql "SELECT COUNT(*) FROM object_values where user_id = #{current_user.id} and
                                               source_id = #{@source.id} and update_type = '#{utype}'"
    else
      # no client_id, just show everything (optionally based on search conditions)
      @object_values=ObjectValue.find_by_sql ObjectValue.get_sql_by_conditions(utype,@source.id,current_user.id,conditions,by_source)
    end
    @object_values.delete_if {|o| o.value.nil? || o.value.size<1 } # don't send back blank or nil OAV triples
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
  
  # wrap object-values by object and source
  def wrap_object_values(ovlist,token)
    @count = 0
    list = {}
    temp_count = @client.client_temp_objects.count
    
    # process the ovlist (this will also include successful create objects)
    ovlist.each do |ov|
      src_name = ov.source.nil? ? nil : ov.source.name
      src_name ||= 'RhoDeleteSource'
      obj_sym = ov.object.nil? ? nil : ov.object.to_sym
      obj_sym ||= :rho_del_obj
      old_obj = nil
      av_hash = { :i => ov.id, :d => ov.db_operation, :a => ov.attrib, :v => ov.value }
                  
      if temp_count > 0
        # find the temp_obj that corresponds to the successful create
        tmp_obj = @client.client_temp_objects.find(:first, :conditions => {:objectid => ov.object, :error => nil})
      end
      old_objid = tmp_obj.temp_objectid if tmp_obj
      if list[src_name]
        if list[src_name][obj_sym]
          list[src_name][obj_sym][:av] << av_hash
          @count +=1
        else
          list[src_name][obj_sym] = { :oo => old_objid, :av => [av_hash] }
          @count +=1
        end
      else
        list[src_name] = { obj_sym => { :oo => old_objid, :av => [av_hash] } }
        @count +=1
      end
    end
    error_objs = ClientTempObject.find(:all, :conditions => "client_id = '#{@client.client_id}' and error is not NULL")
    
    error_objs.each do |err_obj|
      src_name = err_obj.source.nil? ? nil : err_obj.source.name
      if list[src_name]
        list[src_name][err_obj.temp_objectid.to_sym] = { :oo => err_obj.temp_objectid, :e => err_obj.error }
        @count +=1
      else
        list[src_name] = { err_obj.temp_objectid.to_sym => { :oo => err_obj.temp_objectid, :e => err_obj.error } }
        @count +=1
      end
      
      # make sure to set token, this may be the only object in the list
      @token = err_obj.token unless @token
    end
    list
  end

  # creates an object_value list for a given client
  # based on that client's client_map records
  # and the current state of the object_values table
  # since we do a delete_all in rhosync refresh,
  # only delete and insert are required
  def process_objects_for_client(source,client,token,ack_token,resend_token,p_size=nil,first_request=false,by_source=nil)

    # default page size of 10000
    page_size = p_size.nil? ? 10000 : p_size.to_i
    last_sync_time = Time.now
    objs_to_return = []
    by_source_condition = "and ov.source_id=#{source.id}" if by_source
    user_condition = "= #{current_user.id}" if current_user and current_user.id
    user_condition ||= "is NULL"

    # Setup the query conditions
    object_value_conditions = "from object_values ov where ov.update_type='query' #{by_source_condition} and ov.user_id #{user_condition}
        and id not in (select object_value_id from client_maps where client_id='#{client.id}') order by ov.object,ov.id limit #{page_size}"

    object_value_query = "select * #{object_value_conditions}"

    # setup fields to insert in client_maps table
    object_insert_query = "select '#{client.id}',id,'insert','#{token}' #{object_value_conditions}"

    # if we're resending the token, quickly return the results (inserts + deletes)
    if resend_token
      logger.debug "Resending token, resend_token: #{resend_token.inspect}"
      objs_to_return = ClientMap.get_delete_objs_by_token_status(client.id,resend_token)
      client.update_attributes({:updated_at => last_sync_time, :last_sync_token => resend_token})
      objs_to_return.concat( ClientMap.get_insert_objs_by_token_status(client.id,resend_token) )
    else
      logger.debug "ack_token: #{ack_token.inspect}, using new token: #{token.inspect}"

      # mark acknowledged token so we don't send it again
      ClientMap.mark_objs_by_ack_token(ack_token) if ack_token and ack_token.length > 0

      # find delete records
      objs_to_return.concat( ClientMap.get_delete_objs_for_client(token,page_size,client.id) )
      
      # process temp objects for this client
      ClientMap.process_create_objs_for_client(client.id,source.id,token)

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
