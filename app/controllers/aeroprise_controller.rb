#
# This class is specific to Aeroprise application, and not a generally reuseable rhosync component
#

# these gems are not available in normal test env
unless RAILS_ENV=="test"
require 'rubyarapi'
require 'aeroprise'
end

require 'base64'
require 'crypt/blowfish'

class AeropriseController < ApplicationController

  wsdl_service_name 'Aeroprise'
  web_service_api AeropriseApi
  web_service_scaffold :invocation if Rails.env == 'development'
  
  # updates SR and toggle needs attention for it depending on login
  def sr_needs_attention(login, sr_id)
  	logger.debug "login = #{login}"
  	logger.debug "sr_id = #{sr_id}"
  
  	source = Source.find_by_name("AeropriseRequest")
  	    
  	# find all existing copies of the SR in the rhosync cache, summary is required field so we key off that
  	# this code assumes it is possible that more than 1 user has visibility and that user is not the login
  	existing_copies = ObjectValue.find(:all, :conditions => {:source_id=>source.id, :update_type=>'query', :attrib => "summary", :object=>sr_id})
  	users_with_sr = []
  	  	
  	# what if SR is not found?
  	# login as admin to retrieve it and add to reqby and reqfo users if they are already mobilized
  	if existing_copies.empty?
  		api = login
  		request = api.get_user_requests(sr_id)
			if request.blank? || api.error
				logger.fatal "Unable to get SR from remedy #{sr_id}"
				return "ERROR sr_needs_attention"
			end
			
			# now see if we have mobilized users for req for and by and if so add to list 
			# the next step will get the SR for the user
			reqbyid = request["reqbyid"]
			if user = User.find_by_login(reqbyid)
				users_with_sr << user
			end
			
    	reqforid = request["reqforid"]
    	if user = User.find_by_login(reqforid)
				users_with_sr << user
			end
		else
	  	existing_copies.each do |sr|
  			users_with_sr << sr.user
  		end
		end
  	
		# de dup if same user is both reqby and for or admin
		users_with_sr.uniq!
  	
		if users_with_sr.empty?
			logger.info "No mobilized users found at all for this SR--ignoring"
		else
  		# now for each user that has it, process update which will fetch it and push
  		users_with_sr.each do |user|
  			process_needs_attention(user, source, login, sr_id)
			end
		end
	
    "OK sr_needs_attention"
  rescue =>e
    logger.info "exception while responding to WS sr_needs_attention\n #{e.inspect.to_s}"
    logger.info e.backtrace.join("\n")
    "ERROR sr_needs_attention"
  end
  
  def process_needs_attention(user, source, login, sr_id)
  	logger.info "process_needs_attention for #{user.login}, #{login}, #{sr_id}"
  	
    # login as this user, each user might have diferent visibility
    api = login(user.login)
    
		# get this SR from remedy
		request = api.get_user_requests(sr_id)
		if request.blank? || api.error
			logger.fatal "Unable to get SR from remedy #{sr_id}"
			return "ERROR sr_needs_attention"
		end
				
    responses = api.get_answers_for_request(sr_id)
    
    # destroy old sr 
    ObjectValue.destroy_all(:source_id=>source.id, :update_type=>'query', :user_id => user.id, :object=>sr_id)
    
    reqbyid = request["reqbyid"]
    reqforid = request["reqforid"]

    if (login != user.login && (user.login == reqbyid || user.login == reqforid))
    	logger.info "Set NEEDS ATTENTION = 1"
    	request["needsattention"]=1 # flag it so device will know to vibrate
    end
    
    # this function will add as type pending
    hash_values = AeropriseRequestRecord.create(request, responses)
    hash_values.each do |k,v|
    	ObjectValue.create(:source_id=>source.id, :attrib=>k.to_s, :value=>v.to_s, :user_id => user.id, :object=>sr_id)
    end
    
    # flip it to type query
		ActiveRecord::Base.connection.execute "update object_values set update_type='query',id=pending_id where source_id=#{source.id} and object='#{sr_id}' and user_id=#{user.id}"

    # ping the user
    result = user.ping(app_source_url(:app_id => "Aeroprise", :id => "AeropriseRequest"))
    begin
    	logger.info result.inspect.to_s
    	logger.info result.code
    	logger.info result.message
    	logger.info result.body
  	rescue
			logger.info "problem with push request"
  	end
  end
  
  # loginID [Name of the aeroprise user]
  # instanceID [ID for current worklog entry]
  # SRInstanceID [ID for related SR]
  def sr_work_info(login,instance_id,sr_id)
    @source = Source.find_by_name("AeropriseRequest")
     
    # find the user for this SR
    begin
    	user_id = ObjectValue.find(:first, :conditions => {:object=>sr_id, :attrib=>"reqnumber",
        :source_id=>@source.id}).user_id
    rescue
      logger.info "worklog notification for existing SR but #{sr} is not found in sync data. Retrieving SR from remedy."
      return sr_needs_attention(login,sr_id)
    end
    # login as this user
    api = login(login)
    
    # worklog info
    workinfo = api.get_work_info(sr_id)

    worklog = []
    workinfo.each do |entry|
      record = {}
      record["submitter"] = entry["submitter"]
      record["type"] = entry["type"]
      record["summary"] = entry["summary"]
      record["notes"] = entry["notes"]
      record["submitdate"] = entry["submitdate"].to_s
      worklog << record
    end
    
    # serialize array of hashes and update
    @wk_source = Source.find_by_name("AeropriseWorklog")
    ObjectValue.record_object_value(:object=>sr_id, :attrib=>"data",
      :user_id=>user_id, :source_id=>@wk_source.id, :value => RhomRecord.serialize(worklog))
      
    # flag it so device will know to vibrate
    
    # if login != reqbyid && login != reqforid
    reqbyid = ObjectValue.find(:first, :conditions => {:object=>sr_id, :attrib=>"reqbyid",
        :source_id=>@source.id}).value rescue nil
    reqforid = ObjectValue.find(:first, :conditions => {:object=>sr_id, :attrib=>"reqforid",
        :source_id=>@source.id}).value rescue nil
                
    if (login != reqbyid && login != reqforid)
    	ObjectValue.record_object_value(:object=>sr_id, :attrib=>"needsattention",
      	:user_id=>user_id, :source_id=>@source.id, :value => "1")
    end
    
    # ping the user
    user = User.find(user_id)
    user.ping(app_source_url(:app_id=>"Aeroprise", :id => "AeropriseRequest"))
    user.ping(app_source_url(:app_id=>"Aeroprise", :id => "AeropriseWorklog"))
         
    "OK sr_work_info"
  rescue => e
    logger.info "exception while responding to WS sr_work_info #{e.inspect.to_s}"
    logger.info e.backtrace.join("\n")
    "ERROR sr_work_info"
  end
  
  # instanceID [ID for SRD]
  # Status [Current state of SRD two main values 'deployed' and 'expired']
  # activeState [Whether or not the SRD is 'online' or 'offline']
  def srd_notification(instance_id, status, active_state)   
    # if deployed and online, run add and notify
    if (status=='Deployed' && active_state=='Online')
      # start background job to try to get this SRD for each user
      Bj.submit "ruby ./jobs/srd_runner.rb add #{instance_id} #{app_source_url(:app_id=>"Aeroprise", :id => "AeropriseSrd")}"
    end
    
    # if expired or offline, run remove and notify
    if (status=='Expired' || active_state=='Offline')
      # start background job to try to remove this SRD for each user that has it
      Bj.submit "ruby ./jobs/srd_runner.rb remove #{instance_id} #{app_source_url(:app_id=>"Aeroprise", :id => "AeropriseSrd")}"
    end
        
    "OK srd_notification"
  rescue => e
    logger.debug "exception while responding to WS srd_notification #{e.inspect.to_s}"
    logger.debug e.backtrace.join("\n")
    "ERROR srd_notification"
  end
  
  def index
  end
  
  def new_credentials
  	app = App.find_by_name("Aeroprise")
    adminuser = app.configurations.find(:first, :conditions => {:name => 'adminuser'})
    adminpw = app.configurations.find(:first, :conditions => {:name => 'adminpw'})
  	unless adminuser.nil? or adminpw.nil?
    	adminuser.value = Base64.decode64(adminuser.value)
      adminpw.value = Base64.decode64(adminpw.value)
          
      @username,@password = Aeroprise.decrypt(adminuser.value,adminpw.value)
    end
  end
  
  def update_credentials
  	Aeroprise.set_admin_credentials(params['username'], params['password'])
  	redirect_to :action => :index
  end
 
 protected
 
  def login(user_login=nil)
    app = App.find_by_name("Aeroprise")
    ip = app.configurations.find(:first, :conditions => {:name => 'remedyip'})
    port = app.configurations.find(:first, :conditions => {:name => 'remedyport'})
    
    if ip.nil?
      # fatal if no remedy IP address
      raise "no ip"
    end
    
    serverip = ip.value
    port.nil? ? serverport = nil : serverport = port.value   
    
    admin_user = app.configurations.find(:first, :conditions => {:name => 'adminuser'})
    pw = app.configurations.find(:first, :conditions => {:name => 'adminpw'})
      
    unless admin_user.nil? or pw.nil?
      admin_user.value = Base64.decode64(admin_user.value)
      pw.value = Base64.decode64(pw.value)
      
      login,password = Aeroprise.decrypt(admin_user.value,pw.value)
    else
      login,password = "Demo",""
    end

    api = Rubyarapi.new(login,password,serverip,serverport,login,password)
    
    # the user we are impersonating
    api.impersonate(user_login) if user_login
    
    api.get_user_info
    if api.error
      raise "admin login failure" 
    end
    
    logger.debug "login succeeded"
    api
  end
end
