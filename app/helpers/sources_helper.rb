require 'sync'

module SourcesHelper
  
  include ClientsHelper
  include Sync

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

  def needs_refresh(user)
    result=nil
    
    # check to make sure we are not running a paged query in the background
    command = "'ruby script/runner ./jobs/dosync.rb #{credential.user.id} #{id}'%" if credential

    if command
      jobs = Bj::Table::Job.find(:all, :conditions => ["command LIKE ?", command])
  		jobs.each do |job|
  			if job.state == 'running'
  				logger.info "pending background job detected, needs_refresh returning false so it can finish"
  				return false
  			end
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
    
    time=refreshtime(user)
    if !time or ((Time.now - time)>pollinterval)
      logger.info "Refreshing source #{name} #{id}  because the data is old: #{time}"
      return true
    end

    false  # return true of false (nil)
  end
  
  def refreshtime(user)
    obj=Refresh.find(:first, :conditions=>{:user_id=>user.id, :source_id=>self.id})
    obj ? obj.time : nil
  end
  
  def update_refreshtime(user)
    obj=Refresh.find(:first, :conditions=>{:user_id=>user.id, :source_id=>self.id})
    if obj
      obj.update_attribute(:time, Time.now)
    else
      Refresh.create!(:user_id=>user.id, :source_id=>self.id, :time=> Time.now)
    end
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
        dupemsg+=" and OAV: #{prev.object.to_s},#{prev.attrib},#{prev.value}"
        logger.info dupemsg
        ObjectValue.delete(prev.id)
      end
      prev=obj
    end
  end

  # merge in pending objects created by search
  def update_pendings(credential)
    # TODO: must update for all sources returned by SEARCH!
    conditions="source_id=#{id}"
    usr_condition=" and user_id=#{credential.user.id}" if credential
    conditions << usr_condition if usr_condition
    ActiveRecord::Base.transaction do
      # for each unique object, delete entire old version, and finalize new version
      objects = ActiveRecord::Base.connection.select_values "select distinct(object) from object_values where update_type is NULL and #{conditions}"
      objects.each do |obj|
        ActiveRecord::Base.connection.execute "delete from object_values where object='#{obj}' and update_type='query' and #{conditions}"
        ActiveRecord::Base.connection.execute "update object_values set id=pending_id, update_type='query' where object='#{obj}' and #{conditions}"
      end
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
    update_refreshtime(credential.user) if credential
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
          # TODO: should probably limit by user (and client) as well
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
              res = eval(cmd)
              if res and res.is_a?(String) and tmp_object and utype=='create'
                tmp_object.update_attributes(:objectid => res, :source_id => id)
              end
            rescue SourceAdapterLoginException => sae
              if tmp_object
                tmp_object.update_attributes(:error => "#{sae.class}:#{sae}", :source_id => id)
              end           
            rescue Exception => e
              # destroy bad object values
              ObjectValue.find_all_by_object_and_update_type(x.object,utype).each {|ova| ova.destroy}
              if tmp_object
                tmp_object.update_attributes(:error => "#{e.class}:#{e}", :source_id => id)
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
      
      if @source.needs_refresh(current_user)
        if @source.is_paged?
          @object_values=[]
          return
        end
      end

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

      @object_values=ClientMapper.process_objects_for_client(current_user,@source,@client,@token,@ack_token,@resend_token,p_size,@first_request,by_source)
        
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
end
