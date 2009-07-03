require 'digest/md5'
require 'yaml'
require 'open-uri'
require 'net/http'
require 'net/https'

class SourcesController < ApplicationController

  before_filter :login_required, :except => :clientcreate
  before_filter :find_source, :except => :clientcreate
  before_filter :check_device, :except=> :clientcreate
  
  include SourcesHelper
  # shows all object values in XML structure given a supplied source
  # if a :last_update parameter is supplied then only show data that has been
  # refreshed (retrieved from the backend) since then
  protect_from_forgery :only => [:create, :delete, :update]
  
  def callback
    current_user=User.find_by_login params[:login]
    Bj.submit "./script/runner ./jobs/sync_and_ping_user.rb #{current_user.id} #{params[:id]} #{source_show_url(:id => params[:id])}"
  end
  
  # PUSH TO ALL QUEUED UP USERS: (see show method below for queueing mechanism
  # this notifies all users and their devices that have "registered" interest 
  # in an queued sync completion or backend
  #  via a PAP push (BlackBerry BES, iPhone APN push, or SMS (Windows Mobile)
  def ping
    lastslash=request.url.rindex('/')
    @source.callback_url=request.url[0...lastslash-1] if lastslash
    @result=@source.ping
  end
  
  # PUSH TO SPECIFIC USER: 
  # this pings JUST the specified user with the given message
  # defaults to no message, 1/2 second vibrate
  # also provides callback URL of this source's show method but allows for overriding this callback
  def ping_user
    p "Pinging user #{params[:login]}"
    user=User.find_by_login params[:login] if params[:login]
    if user.nil?
      logger.info "Failed to find user to notify: #{params[:login]}"
    else
      callback_url=params[:callback_url]
      lastslash=request.url.rindex('/') if callback_url.nil? # compute the callback if not supplied
      callback_url=request.url[0...lastslash-1] if lastslash  # as the show method on this controller
      if callback_url
        @result=user.ping(callback_url, params[:message],params[:vibrate])  # only does the notify if we have a message and a callback
      end
    end
    @result
  end
  
  # PUSH CAPABILITY: 
  # IF you wish to have device pinged when the queued sync is complete 
  # THEN supply params["device_pin"] and params["device_type"] 
  def show
    if params["id"] == "rho_credential"
      render :text => "[]" and return
    end
   
    @app=@source.app
    if !check_access(@app)  
      render :action=>"noaccess"
    else 
      usersub=@app.memberships.find_by_user_id(current_user.id) if current_user
      @source.credential=usersub.credential if usersub # this variable is available in your source adapter    
      @source.refresh(@current_user,session) if params[:refresh] || @source.needs_refresh 

      # if client_id is provided, return only relevant objects for that client
      if params[:client_id]
        @client = setup_client(params[:client_id])
        @ack_token = params[:ack_token]
        @first_request=false
        @resend_token=nil
        
        # setup the conditions to handle the client request
        if @ack_token
          logger.debug "[sources_controller] Received ack_token,
                          ack_token: #{@ack_token.inspect}, new token: #{@token.inspect}"
        else
          # get last token if available, otherwise it's the first request
          # for a given source
          @resend_token=@client.last_sync_token
          if @resend_token.nil?
            @first_request=true
            logger.debug "[sources_controller] First request for source"
          end
        end 
        
        # generate new token for the next set of data
        @token=@resend_token ? @resend_token : get_new_token
        # get the list of objects
        # if this is a queued sync source and we are doing a refresh in the queue then wait for the queued sync to happen
        if @source.queuesync and @source.needs_refresh
          @object_values=[]
        else
          @object_values=process_objects_for_client(@source,@client,@token,@ack_token,@resend_token,params[:p_size],@first_request)
        end
        # set token depending on records returned
        # if we sent zero records, we need to keep track so the client 
        # doesn't receive the last page again
        @token=nil if @object_values.nil? or @object_values.length == 0
        
        logger.debug "[sources_controller] Finished processing objects for client,
                        token: #{@token.inspect}, last_sync_token: #{@client.last_sync_token.inspect},
                        updated_at: #{@client.updated_at}, object_values count: #{@object_values.length}"
      else
        # no client_id, just show everything
        @object_values=ObjectValue.find_by_sql object_values_sql('query')
      end
      @object_values.delete_if {|o| o.value.nil? || o.value.size<1 }  # don't send back blank or nil OAV triples
      p "Sending #{@object_values.length} records to #{params[:client_id]}" if params[:client_id] and @object_values
      respond_to do |format|
        format.html 
        format.xml  { render :xml => @object_values}
        format.json
      end
    end
  rescue SourceAdapterLoginException
    logout_killing_session!
    render :nothing=>true, :status => 401
  end
  
  # quick synchronous simple query that doesn't hit the database
  # parameters:
  #   question
  def ask
    @app=@source.app
    @token=get_new_token
    if params[:question]
      @object_values=@source.ask(@current_user,params)
      @object_values.delete_if {|o| o.value.nil? || o.value.size<1 }  # don't send back blank or nil OAV triples
    else
      raise "You need to provide a question to answer"
    end

    @object_values.collect! { |x|
       x.id = x.hash_from_data(x.attrib,x.object,x.update_type,x.source_id,x.user_id,x.value)
       x.db_operation = 'insert'
       x.update_type = 'query'
       x
    }
    respond_to do |format|
      format.html { render :action=>"show"}
      format.xml  { render :action=>"show"}
      format.json { render :action=>"show"}
    end
  end


  # return the metadata for the specified source
  # ONLY FOR SUBSCRIBERS/ADMIN
  def attributes
    check_access(@source.app)
    # get the distinct list of attributes that is available
    @attributes=ObjectValue.find_by_sql "select distinct(attrib) from object_values where source_id="+@source.id

    respond_to do |format|
      format.html
      format.xml  { render :xml => @attributes}
      format.json { render :json => @attributes}
    end
  end
  
  # generate a new client for this source
  def clientcreate
    @client = Client.new
    
    respond_to do |format|
      if @client.save
        format.json { render :json => @client }
        format.xml  { head :ok }
      end
    end
  end


  # this creates all of the rows in the object values table corresponding to
  # the array of hashes given by the attrvals parameter
  # note that the REFRESH action below will later DELETE all of the created records
  #
  # also note YOU MUST CREATE A TEMPORARY OBJECT ID. Some form of hash or CRC
  #  of all of the values can be used
  #
  # for example
  # :attrvals=
  #   [{"object"=>"temp1","attrib"=>"name","value"=>"rhomobile"},
  #   {"object"=>"temp1","attrib"=>"industry","value"=>"software"},
  #   {"object"=>"temp1","attrib"=>"employees","value"=>"500"}
  #   {"object"=>"temp2","attrib"=>"name","value"=>"mobio"},
  #   {"object"=>"temp2","attrib"=>"industry","value"=>"software"},
  #   {"object"=>"temp3","attrib"=>"name","value"=>"xaware"},
  #   {"object"=>"temp3","attrib"=>"industry","value"=>"software"}]
  #
  # RETURNS:
  #   a hash of the object_values table ID columns as keys and the updated_at times as values
  def createobjects
    @app=App.find_by_permalink(params[:app_id]) if params[:app_id]
    if params[:id]=="rho_credential" # its trying to create a credential on the fly
      @sub=Membership.find_or_create_by_user_id_and_app_id current_user.id,@app.id  # find the just created membership subscription
      
      # create new credential
      unless @sub.credential
        @sub.credential = Credential.create 
      end
      
      urlattribs=params[:attrvals].select {|av| av["attrib"]=="url"}
      @sub.credential.url=urlattribs[0]["value"] if urlattribs.present?
    
      loginattribs=params[:attrvals].select {|av| av["attrib"]=="login"}
      @sub.credential.login=loginattribs[0]["value"] if loginattribs.present?
          
      passwordattribs=params[:attrvals].select {|av| av["attrib"]=="password"}
      @sub.credential.password=passwordattribs[0]["value"] if passwordattribs.present?

      tokenattribs=params[:attrvals].select {|av| av["attrib"]=="token"}      
      @sub.credential.token=tokenattribs[0]["value"] if tokenattribs.present?
    
      @sub.credential.save
      @sub.save
      
      objects = []
    else  # just put the (noncredential) data into ObjectValues to get picked up by the backend source adapter
      @source=Source.find_by_permalink(params[:id]) if params[:id]
      check_access(@source.app)
      objects={}
      @client = Client.find_by_client_id(params[:client_id]) if params[:client_id]

      params[:attrvals].each do |x| # for each hash in the array
        # note that there should NOT be an object value for new records
        o=ObjectValue.new
        o.object=x["object"]
        o.attrib=x["attrib"]
        o.value=x["value"]
        o.update_type="create"
        o.source=@source
        o.user_id=current_user.id
        
        if x["attrib_type"] and x["attrib_type"] == 'blob'
          o.blob = params[:blob]
          o.blob.instance_write(:file_name, x["value"])
        end
        o.save
        # add the created ID + created_at time to the list
        objects[o.id]=o.created_at if not objects.keys.index(o.id)  # add to list of objects
      end
    end
    @object_values = ObjectValue.find_by_sql object_values_sql('create')
    respond_to do |format|
      if params[:no_redirect]
        format.html { 
          flash[:notice]="Created objects"
          render :action=>"show",:id=>@source.id,:app_id=>@source.app.id
        }
      else
        format.html { 
          flash[:notice]="Created objects"
          redirect_to :action=>"show",:id=>@source.id,:app_id=>@source.app.id
        }
      end
      format.xml  { render :xml => objects }
      format.json  { render :json => objects }
    end
  rescue SourceAdapterLoginException
    logout_killing_session!
    render :nothing=>true, :status => 401
  end

  # this creates all of the rows in the object values table corresponding to
  # the array of hashes given by the attrval parameter.
  # note that the REFRESH action below will later DELETE all of the created records
  #  # for example
  # :attrvals=
  #   [{"object"=>"1","attrib"=>"name","value"=>"rhomobile"},
  #   {"object"=>"1","attrib"=>"industry","value"=>"software"},
  #   {"object"=>"1","attrib"=>"employees","value
  #   {"object"=>"2","attrib"=>"name","value"=>"mobio"},
  #   {"object"=>"2","attrib"=>"industry","value"=>"software"},
  #   {"object"=>"3","attrib"=>"name","value"=>"xaware"},
  #   {"object"=>"3","attrib"=>"industry","value"=>"software"}]
  #
  # RETURNS:
  #   a hash of the object_values table ID columns as keys and the updated_at times as values
  def updateobjects
    check_access(@source.app)
    objects={}
    params[:attrvals].each do |x|  # for each hash in the array
       o=ObjectValue.new
       o.object=x["object"]
       o.attrib=x["attrib"]
       o.value=x["value"]
       o.update_type="update"
       o.user_id=current_user.id
       o.source=@source
       o.save
       # add the created ID + created_at time to the list
       objects[o.id]=o.created_at if not objects.keys.index(o.id)  # add to list of objects
    end

    respond_to do |format|
      format.html { 
        flash[:notice]="Updated objects"
        redirect_to :action=>"show",:id=>@source.id,:app_id=>@source.app.id
      }
      format.xml  { render :xml => objects }
      format.json  { render :json => objects }
    end
  rescue SourceAdapterLoginException
    logout_killing_session!
    render :nothing=>true, :status => 401
  end

  # this creates all of the rows in the object values table corresponding to
  # the hash given by attrvals.
  # note that the REFRESH action below will later DELETE all of the created records
  #
  # RETURNS:
  #   a hash of the object_values table ID columns as keys and the updated_at times as values
  def deleteobjects
    check_access(@source.app)
    objects={}
    params[:attrvals].each do |x|
       o=ObjectValue.new
       o.object=x["object"]
       o.attrib=x["attrib"] if x["attrib"]
       o.value=x["value"] if x["value"]
       o.update_type="delete"
       o.source=@source
       o.user_id=current_user.id
       o.save
       # add the created ID + created_at time to the list
       objects[o.id]=o.created_at if not objects.keys.index(o.id)  # add to list of objects
    end

    respond_to do |format|
      format.html do
            flash[:notice]="Deleted objects"
            redirect_to :action=>"show"
      end
      format.xml  { render :xml => objects }
      format.json { render :json => objects }
    end
    
  rescue SourceAdapterLoginException
    logout_killing_session!
    render :nothing=>true, :status => 401
  end

  def editobject
    # bring up an editing form for
    @object=ObjectValue.find_by_source_id_and_object_and_attrib @source.id,params[:object],params[:attrib]
  end

  def newobject
  end

  def pick_load
    # go to the view to pick the file to load
  end

  def load_all
    # NOTE: THIS DOES NOT WORK FROM OUR SAVING FORMAT RIGHT NOW! (the one that save_all does)
    # it only works from the YAML format in db/migrate/sources.yml
    # this is a very well reported upon Ruby/YAML issue
    @sources=YAML::load_file params[:yaml_file]
    p @sources
    @sources.keys.each do |x|
      source=Source.new(@sources[x])
      source.save
    end
    flash[:notice]="Loaded sources"
    redirect_to :action=>"index"
  end

  def pick_save
    # go to the view to pick the file
    @app=App.find_by_permalink params[:app_id] if params[:app_id]
  end

  def save_all
    if params[:app_id].nil?
      @app=App.find_by_admin request.headers['login']
    else
      @app=App.find_by_permalink params[:app_id] 
      @sources=@app.sources if @app
    end
    File.open(params[:yaml_file],'w') do |out|
      @sources.each do |x|
        YAML.dump(x,out)
      end
    end
    flash[:notice]="Saved sources"
    redirect_to :action=>"index"
  end
  
  # GET /sources
  # GET /sources.xml
  # this returns all sources that are associated with a given "app" as determine by the token
  def index    
    login=current_user.login
    if params[:app_id].nil?
      @app=App.find_by_admin login
    else
      @app=App.find_by_permalink params[:app_id] 
    end
    @sources=@app.sources if @app
        
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sources }
    end
  end

  # GET /sources/new
  # GET /sources/new.xml
  def new
    @source = Source.new
    
    @app=App.find_by_permalink params[:app_id] if params[:app_id]
    @source.app=@app
    if @app.sources.size > 0 # default the url,login and password
      @source.url=@app.sources[0].url
      @source.login=@app.sources[0].login
      @source.password=@app.sources[0].password
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @source }
    end
  end

  # GET /sources/1/edit
  def edit
    if current_user.nil?
      redirect_to :controller=>:sessions,:action=>:new 
    else
      p "Current user: " + current_user.login
    end
    @source=Source.find_by_permalink params[:id]
    @app=@source.app
    @apps=Administration.find_all_by_user_id(current_user.id) 
    render :action=>"edit"
  end

  # POST /sources
  # POST /sources.xml
  def create
    @source = Source.new(params[:source])
    error=nil
    if Source.find_by_name @source.name
      error="Source already exists. Please try a different name."
    end
    @app=App.find_by_permalink params["source"]["app_id"]
    @source.app=@app
    respond_to do |format|
      if !error and @source.save
        flash[:notice] = 'Source was successfully created.'
        format.html { redirect_to(:controller=>"apps",:action=>:edit,:id=>@app.id) }
        format.xml  { render :xml => @source, :status => :created, :location => @source }
      else
        flash[:notice]=error
        format.html { render :action => "new" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sources/1
  # PUT /sources/1.xml
  def update
    @app=App.find_by_permalink params["source"]["app_id"]
    error=nil
    src=Source.find_by_name params["source"]["name"]
    if src and src!=@source
      error="Source name already exists. Please try a different name." 
    else
      @app=App.find_by_permalink params["source"]["app_id"]
      @source.app=@app
    end
    respond_to do |format|
      begin
        if !error and@source.update_attributes(params[:source])
          flash[:notice] = 'Source was successfully updated.'
          format.html { redirect_to(:controller=>"apps",:action=>:edit,:id=>@app.id) }
          format.xml  { head :ok }
        else
          if error 
            flash[:notice]=error
          else 
            begin  # call underlying save! so we can get some exceptions back to report
              # (update_attributes just calls save
              @source.save!
            rescue Exception
              flash[:notice] = $!
            end
          end
          format.html { render :action => "edit",:id=>@app.id }
          format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
        end
      end
    end

  end

  # DELETE /sources/1
  # DELETE /sources/1.xml
  def destroy
    @source.destroy
    @app=App.find_by_permalink params[:app_id]
    respond_to do |format|
      format.html { redirect_to :controller=>"apps",:action=>"edit",:id=>@app.id }
      format.xml  { head :ok }
    end
  end
  
  def noaccess
  end
  
  def test_createobjects
    respond_to do |format|
      format.html
    end
  end
  
  def viewlog
    @logs=SourceLog.find :all, :conditions=>{:source_id=>@source.id},:order=>"updated_at desc"
  end

protected
  def get_new_token
    ((Time.now.to_f - Time.mktime(2009,"jan",1,0,0,0,0).to_f) * 10**6).to_i
  end
  
  def find_source
    @source=Source.find_by_permalink(params[:id]) if params[:id]
  end
  
  def object_values_sql(utype)
    objectvalues_cmd="select * from object_values where update_type='#{utype}' and source_id=#{@source.id}"
    objectvalues_cmd << " and user_id=" + @source.credential.user.id.to_s if @source.credential
    objectvalues_cmd << " order by object,attrib"
  end
end
