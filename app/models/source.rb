# == Schema Information
# Schema version: 20090624184104
#
# Table name: sources
#
#  id           :integer(4)    not null, primary key
#  name         :string(255)   
#  url          :string(255)   
#  login        :string(255)   
#  password     :string(255)   
#  created_at   :datetime      
#  updated_at   :datetime      
#  refreshtime  :datetime      
#  adapter      :string(255)   
#  app_id       :integer(4)    
#  pollinterval :integer(4)    
#  priority     :integer(4)    
#  incremental  :integer(4)    
#  queuesync    :boolean(1)    
#  limit        :string(255)   
#  callback_url :string(255)   
class Source < ActiveRecord::Base
  include SourcesHelper
  
  has_many :object_values
  has_many :source_logs
  has_many :source_notifies
  has_many :users, :through => :source_notifies
  belongs_to :app
  attr_accessor :source_adapter,:current_user,:credential
  validates_presence_of :name,:adapter
  
  def initadapter(credential,session)
    #create a source adapter with methods on it if there is a source adapter class identified
    if (credential and credential.url.blank?) and (!credential and self.url.blank?)
      msg= "Need to to have a URL for the source in either a user credential or globally"
      slog(nil,msg,self.id)
      raise msg
    end
    if not self.adapter.blank? 
      begin
        p "Creating class for #{self.adapter}"
        @source_adapter=(Object.const_get(self.adapter)).new(self,credential) 
        @source_adapter.session = session if session
      rescue Exception=>e
        msg="Failure to create adapter from class #{self.adapter}: #{e.inspect.to_s}"
        p msg
        slog(nil,msg)
      end
    else # if source_adapter is nil it will
      @source_adapter=nil
    end
    @source_adapter
  end
  
  # used by dosync and backpages
  def setup_credential_adapter(current_user,session)
    logger.debug "Logged in as: "+ current_user.login if current_user  
    usersub=app.memberships.find_by_user_id(current_user.id) if current_user
    self.credential=usersub.credential if usersub # this variable is available in your source adapter
    source_adapter=initadapter(self.credential,session)   
    
    if source_adapter.nil? 
      slog(nil,"Couldn't set up source adapter due to missing or invalid class")
      return
    end 
    source_adapter
  end
  
  # executes synchronous search for records that meet specified criteria of conditions returned in specified order
  # calls source adapter query method with conditions and order
  def dosearch(current_user,session=nil,conditions=nil,limit=nil,offset=nil)
    logger.debug "dosearch called"
    @current_user=current_user
    source_adapter=setup_credential_adapter(current_user,session)
    begin
      source_adapter.login  # should set up @session_id
    rescue Exception=>e
      logger.debug "Failed to login #{e}"      
      logger.debug e.backtrace.join("\n")
      return
    end
    clear_pending_records(self.credential)
    begin  
      logger.debug "Calling query with conditions: #{conditions.inspect.to_s}, limit: #{limit.inspect.to_s}, offset: #{offset.inspect.to_s}"
      source_adapter.query(conditions,limit,offset)
      source_adapter.sync
      update_pendings(@credential,true)  # copy over records that arent already in the sandbox (second arg says check for existing)
    rescue Exception=>e
      logger.debug "Failed to sync #{e}"
      logger.debug e.backtrace.join("\n")
    end 
  end
   
  def refresh(current_user, session, url=nil)
    if queuesync==1 # queue up the sync/refresh task for processing by the daemon with doqueuedsync (below)
      # Also queue it up for BJ (http://codeforpeople.rubyforge.org/svn/bj/trunk/README)
      Bj.submit "ruby script/runner ./jobs/sync_and_ping_user.rb #{current_user.id} #{id} #{url}",
        :tag => current_user.id.to_s
      logger.debug "Queued up task for user "+current_user.login+ ", source "+ name
    else # go ahead and do it right now
      dosync(current_user, session)
    end
  end
  
  def dosync(current_user,session=nil)
    @current_user=current_user
    source_adapter=setup_credential_adapter(current_user,session)
    # make sure to use @client and @session_id variable in your code that is edited into each source!
    begin
      start=Time.new
      source_adapter.login  # should set up @session_id
      tlog(start,"login",self.id)  # log how long it takes to do the login
    rescue Exception=>e
      logger.info "Failed to login"
      slog(e,"can't login",self.id,"login")
      raise e
    end
    # first grab out all ObjectValues of updatetype="qparms"
    # put those together into a qparms hash
    # qparms is nil if there is no such hash
    qparms=qparms_from_object(current_user.id)
    # must do it before the create processing below!
    begin 
      process_update_type('create')
      cleanup_update_type('create')
    rescue Exception=>e
      slog(e, "Failed to create",self.id,"create")
      raise e
    end 

    begin
      process_update_type('update')
      cleanup_update_type('update')
    rescue Exception=>e
      slog(e, "Failed to update",self.id,"update")
      raise e
    end
    
    begin
      process_update_type('delete')
      cleanup_update_type('delete')
    rescue Exception=>e
      slog(e, "Failed to delete",self.id,"delete")
      raise e
    end
        
    clear_pending_records(self.credential)

    # query,sync,finalize are atomic
    begin  
      source_adapter.qparms=qparms if qparms  # note that we must have an attribute called qparms in the source adapter for this to work!
      # look for source adapter page method. if so do paged query 
      # see spec at http://wiki.rhomobile.com/index.php/Writing_RhoSync_Source_Adapters#Paged_Queries
      if defined? source_adapter.page 
        source_adapter.page(0)
        # then do the rest in background using the page_query.rb script
        cmd="ruby script/runner ./jobs/page_query.rb #{current_user.id} #{id} 1"
        p "Executing background job: #{cmd} #{current_user.id.to_s}"
        begin 
          Bj.submit cmd,:tag => current_user.id.to_s
        rescue =>e
          p "Failed to execute #{e.to_s}"
          p e.backtrace.join("\n")
        end
        tlog(start,"page",self.id)
        start=Time.new
      else       
        start=Time.new
        source_adapter.query
        tlog(start,"query",self.id)
      end        
      
      start=Time.new
      source_adapter.sync
      tlog(start,"sync",self.id)
      start=Time.new
      finalize_query_records(@credential)
      tlog(start,"finalize",self.id)
    rescue Exception=>e
      p "Failed to query,sync: #{e.to_s}"
      slog(e,"Failed to query,sync",self.id)
      p e.backtrace.join("\n")
    end 
    source_adapter.logoff
  end
  
  # used by background job for paged query (page_query.rb script)
  # queries the second (1-th) through last page
  def backpages(pagenum=1)
    # first detect if some background (backpages) job is already working against this source and user
    logger.info "Backpages called"
=begin
    lock=ObjectValue.find_by_source_id_and_user_id_and_update_type id,self.current_user.id,"lock"
    if lock 
      logger.info "Background job already running for source #{id} and user #{current_user.id}"
      return # cant do another background job
    end  
    # otherwise create a lock and do the query
    lock=ObjectValue.new(:source_id=>id,:user_id=>user_id,:update_type=>"lock")
    lock.save
=end

    source_adapter=setup_credential_adapter(current_user,nil)
    # make sure to use @client and @session_id variable in your code that is edited into each source!
    begin
      start=Time.new
      source_adapter.login  # should set up @session_id
      tlog(start,"login",self.id)  # log how long it takes to do the login
    rescue Exception=>e
      logger.info "Failed to login"
      slog(e,"can't login",self.id,"login")
      raise e
    end
    
    result=true
    @source=self
    while result 
      logger.info "Calling page #{pagenum}"      
      result=source_adapter.page(pagenum)
      logger.info "Syncing #{pagenum}"      
      source_adapter.sync
      pagenum=pagenum+1
    end
    finalize_query_records(credential)
=begin    
    lock.delete
=end
  end
  
  
  def ask(current_user,question)
    usersub=app.memberships.find_by_user_id(current_user.id) if current_user
    self.credential=usersub.credential if usersub # this variable is available in your source adapter
    initadapter(self.credential)
    start=Time.new
    result=source_adapter.ask question
    tlog(start,"ask",self.id)
    result
  end

  def do_callback
    current_user=User.find_by_login params[:login]
    refresh(current_user)
  end

  def ping
    # this is the URL for the show method
    @result=""
    users.each do |user|
      @result+=user.ping(callback_url) # this will ping all clients owned by that user
    end
  end
  
  def before_validate
    self.initadapter
  end

  def before_save
    self.pollinterval||=300
    self.priority||=3
  end
  
  def to_param
    name.gsub(/[^a-z0-9]+/i, '-') unless new_record?
  end
  
  def self.find_by_permalink(link)
    Source.find(:first, :conditions => ["id =:link or name =:link", {:link=> link}])
  end
end
