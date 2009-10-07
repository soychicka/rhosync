require 'digest/md5'
require 'yaml'
require 'open-uri'
require 'net/http'
require 'net/https'
require 'source_adapter'

class SourcesController < ApplicationController

  before_filter :login_required, :except => :clientcreate
  before_filter :find_source, :except => :clientcreate
  before_filter :check_version, :only => [:show, :search]
  
  UNSUPPORTED_VERSIONS = [1]
  SUPPORTED_VERSIONS = [2]

  include SourcesHelper
  # shows all object values in XML structure given a supplied source
  # if a :last_update parameter is supplied then only show data that has been
  # refreshed (retrieved from the backend) since then
  protect_from_forgery :only => [:create, :delete, :update]

  def callback
    current_user=User.find_by_login params[:login]
    @app=@source.app
    Bj.submit "ruby script/runner ./jobs/sync_and_ping_user.rb #{current_user.id} #{params[:id]} #{app_source_url(:app_id=>@app.name, :id => @source.name)}",
       :tag => current_user.id.to_s
    render(:nothing=>true, :status=>200)
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
    logger.info "Pinging user #{params[:login]}"
    user=User.find_by_login params[:login] if params[:login]
    if user.nil?
      logger.error "Failed to find user to notify: #{params[:login]}"
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

  # shows ALL data from backend, refreshing data when necessary (if data is empty or "stale")
  # use search method if you wish to request specific data
  # IF you wish to have device pinged when by ping method for important events
  # THEN supply params["device_pin"] and params["device_type"]
  def show
    if params["id"] == "rho_credential"
      render :text => "[]" and return
    end
    @app=@source.app
    if !check_access(@app)
      respond_to do |wants|
        wants.html { render :action=>"noaccess" }
        wants.xml  { render :xml => { :error => "No Access" } }
      end
    else
      if @current_user and usersub=@app.memberships.find_by_user_id(@current_user.id)
        @source.credential=usersub.credential  # this variable is available in your source adapter
      end
      @source.refresh(@current_user,session, app_source_url(:app_id=>@app.name, :id => @source.name)) if params[:refresh] || @source.needs_refresh
      build_object_values('query',params[:client_id],params[:ack_token],params[:p_size],params[:conditions],true)
      get_wrapped_list(@object_values)
      @count = @count.nil? ? @object_values.length : @count
      handle_show_format
    end
  end

  def edit_search
    @source=Source.find_by_permalink params[:id]
    @app=@source.app
  end

  # queries for specific data from backend
  # parameters:
  #  order- hash of values to be sent to the backend adapter to effect a query
  #  offset - optional argument of how far into the query we are, NONZERO VALUE MEANS USE CURRENT CACHE
  #  limit - optional number of rows to return
  #  conditions - hash of name-values for query
  def search
    @source=Source.find_by_permalink params[:id]
    @app=@source.app
    if !check_access(@app)
      render :action=>"noaccess"
    else
      if @current_user and usersub=@app.memberships.find_by_user_id(@current_user.id)
        @source.credential=usersub.credential  # this variable is available in your source adapter
      end
      if params[:conditions].is_a?(Array)
        conditions=nvlist_to_hash(params[:conditions])
      else
        conditions=params[:conditions]
      end

      logger.debug "Searching for #{conditions.inspect.to_s}"

      @source.dosearch(@current_user,session,conditions,params[:max_results].to_i,params[:offset].to_i)
      build_object_values('query',params[:client_id],params[:ack_token],params[:p_size],conditions,false)
      get_wrapped_list(@object_values)
      @count = @count.nil? ? @object_values.length : @count
      handle_show_format
    end
  end

  # generate a new client for this source
  def clientcreate
    @client = Client.new
    @client.user = current_user if current_user

    respond_to do |format|
      if @client.save
        format.json { render :json => @client }
        format.xml  { head :ok }
      end
    end
  end

  # register client for for push notifications
  def clientregister
    find_and_register_client
    render :nothing => true, :status => 200
  end

  # reset client_maps data
  def clientreset
    @client = Client.find_by_client_id(params[:client_id])
    if @client
      @client.reset
    end
    render :nothing=> true, :status => 200
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
    @source=Source.find_by_permalink(params[:id]) if params[:id]
    check_access(@source.app)
    objects={}
    @client = Client.find_by_client_id(params[:client_id]) if params[:client_id]

    newqparms=1 # flag that tells us that the first time we have an object named qparms we need to change query parameters
    params[:attrvals].each do |x| # for each hash in the array
      # note that there should NOT be an object value for new records
      o=ObjectValue.new
      o.object=x["object"]
      o.attrib=x["attrib"]
      o.value=x["value"]
      if x["object"]=="qparms"
        cleanup_update_type("qparms",current_user.id)  # delete the existing qparms objects
        newqparms=nil  # subsequent qparms objects just add to the qparms objectvalue triples
        o.update_type="qparms"
      else
        o.update_type="create"
      end
      o.source=@source
      o.user_id=current_user.id

      if x["attrib_type"] and x["attrib_type"] == 'blob'
        o.blob = params[:blob]
        o.blob.instance_write(:file_name, x["value"])
      end
      unless @client.client_temp_objects.exists?(:temp_objectid => x['object'])
        @client.client_temp_objects.create!(:temp_objectid => x['object'], :source_id => @source.id) 
      end
      o.save
      # add the created ID + created_at time to the list
      objects[o.id]=o.created_at if not objects.keys.index(o.id)  # add to list of objects
      
      ClientMap.create!(:client_id => @client.client_id, :object_value_id => o.id)
    end
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
      logger.info "Current user: " + current_user.login
    end
    @source=Source.find_by_permalink params[:id]
    @app=@source.app
    @apps=Administration.find_all_by_user_id(current_user.id)
    render :action=>"edit"
  end

  # POST /apps/:app_id/sources
  # POST /apps/:app_id/sources.xml
  #
  # Example xml request body:
  # <source>
  #   <name>product</name>
  #   <adapter>product</adapter>
  # </source>
  def create
    @source = Source.new(params[:source])
    error=nil
    if Source.find_by_name(@source.name)
      error="Source already exists. Please try a different name."
    end
    @app=App.find_by_permalink(params[:source][:app_id])
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
    flash[:notice] = 'Source was successfully deleted.'
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


protected
  def check_version
    @version = params[:version]
    if @version
      @version = @version.to_i
      if UNSUPPORTED_VERSIONS.include?(@version)
        render :text => "This server only supports the following protocol version(s): #{SUPPORTED_VERSIONS.join(',')}.  Please update your rhodes client.", :status => 404 and return
      end
    end
  end

  def handle_show_format
    respond_to do |format|
      format.html
      format.xml  { render :xml => @object_values }
      if @version and @version == 2
        format.json { render :template => "sources/show.json_v2.erb" }
      else
        format.json
      end
    end
  end

  def get_new_token
    ((Time.now.to_f - Time.mktime(2009,"jan",1,0,0,0,0).to_f) * 10**6).to_i
  end

  def find_source
    @source=Source.find_by_permalink(params[:id]) if params[:id]
  end

  def nvlist_to_hash(nvlist)
    attrvals={}
    nvlist.each { |nv| attrvals[nv["name"]]=nv["value"] if nv["name"] and nv["value"] and nv["name"].size>0}
    attrvals
  end
  
  def get_wrapped_list(ovlist)
    @wrapped_list = wrap_object_values(ovlist,@token) if @version
  end
end
