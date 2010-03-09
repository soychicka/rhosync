#
# This script is specific to Aeroprise application, and not a generally reuseable rhosync component
#

# def sr_crud(login, sr_id, modified_by)

logfile = File.open("log/bj-aeroprise_sr_crud.log", "a+")  
logger = Logger.new(logfile)

login_name        = ARGV[0]
sr_id 			 			= ARGV[1]
modified_by 			= ARGV[2]
req_callback_url  				= ARGV[3]
worklog_callback_url  		= ARGV[4]

logger.debug "login_name = #{login_name}, sr_id = #{sr_id}, modified_by = #{modified_by} req_callback_url =#{req_callback_url} worklog_callback_url=#{worklog_callback_url}"

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
    raise "admin user name and password needed, but not found in DB"
  end

  api = Rubyarapi.new(login,password,serverip,serverport,login,password)
    
  # the user we are impersonating
  api.impersonate(user_login) if user_login
    
  api.get_user_info
  if api.error
    raise "admin login failure" 
  end
    
  api
end

# find this user
user = User.find_by_login(login_name)
if user.nil?
	logger.info "Mobilized user never synced with rhosync, skipping"
	return
end
			
# login as this user
api = login(login_name)

# get this SR from remedy
request = api.get_user_requests(sr_id)
if request.blank? || api.error
  logger.fatal "Unable to get SR from remedy #{sr_id}"
  return
end
				
responses = api.get_answers_for_request(sr_id)
if api.error
  logger.fatal "Unable to get responses from remedy"
  return
end
    
source = Source.find_by_name("AeropriseRequest")
      	
# destroy old sr 
ObjectValue.destroy_all(:source_id=>source.id, :update_type=>'query', :user_id => user.id, :object=>sr_id)

request_cancelled = (request["appreqstatus"] == "Canceled") || (request["status"].to_i==8000)
  	  
# if request is now cancelled we dont add back but just leave deleted and let normal sync handle it
if !request_cancelled
  if (login_name != modified_by)
	  logger.info "Set vibrate = 1"
	  request["vibrate"] = 1 # flag it so device will know to vibrate
  end
    
  # this function will add as type pending
  hash_values = AeropriseRequestRecord.create(request, responses)
  #hash_values.each do |k,v|
  #  ObjectValue.create(:source_id=>source.id, :attrib=>k.to_s, :value=>v.to_s, :user_id => user.id, :object=>sr_id)
  #end

  # enter values the same way they are done in source adapter 
  default_sync = Sync::Synchronizer.new({sr_id => hash_values}, source.id, 1000000, user.id)
  default_sync.sync
    
  # flip it to type query
  begin
	  ActiveRecord::Base.connection.execute "update object_values set update_type='query',id=pending_id where source_id=#{source.id} and object='#{sr_id}' and user_id=#{user.id}"
  rescue
	  logger.info "WARNING: problem flipping request to type query... assuming record already exists and continuing..."
  end
end # request cancelled

# ping the user
result = user.ping(req_callback_url)
begin
	logger.info result.inspect.to_s
	logger.info result.code
	logger.info result.message
	logger.info result.body
rescue
	logger.info "problem with push request, response was nil"
end
  
# same thing, dont bother if request is cancelled	
if !request_cancelled
  # now queue request to get worklog unless there is already one queued
  command = "'ruby script/runner ./jobs/aeroprise_sr_work_info.rb #{login} #{sr_id}'%"

  jobs = Bj::Table::Job.find(:all, :conditions => ["command LIKE ?", command])
  jobs.each do |job|
	  if job.state == 'running' || job.state == 'pending'
	  	logger.info "found pending job to get workinfo so skipping and returning"
	  	return
	  end
  end
	
  # queue new job for work log, but pass "nil" as this callback URL as flag so we dont loop back here if sr cannot be read fgor example
  Bj.submit "'ruby script/runner ./jobs/aeroprise_sr_work_info.rb #{login_name} #{sr_id} FALSE nil #{worklog_callback_url}'"
end