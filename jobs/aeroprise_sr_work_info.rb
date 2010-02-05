#
# This script is specific to Aeroprise application, and not a generally reuseable rhosync component
#

# def sr_work_info(login,instance_id,sr_id,needs_attention)

logfile = File.open("log/bj-aeroprise_sr_work_info.log", "a+")  
logger = Logger.new(logfile)

login_name        				= ARGV[0]
sr_id 			 							= ARGV[1]
needs_attention						= ARGV[2]
req_callback_url  				= ARGV[3]
worklog_callback_url  		= ARGV[4]

logger.debug "login_name = #{login_name}, sr_id = #{sr_id}, needs_attention = #{needs_attention} req_callback_url =#{req_callback_url} worklog_callback_url=#{worklog_callback_url}"

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
  	
source = Source.find_by_name("AeropriseRequest")
     
# find the user
user = User.find_by_login(login_name)
if user.nil?
	logger.info "Mobilized user never synced with rhosync, skipping....."
	return
end
		
ov = ObjectValue.find(:first, :conditions => {:object=>sr_id, :attrib=>"reqnumber",
    :source_id=>source.id, :user_id => user.id})
    
if ov.nil?
  logger.info "worklog notification for SR #{sr_id} not found in sync data for #{login_name}."
  
  # shorter than this means we were called from jobs/aeroprise_sr_crud.rb so dont loop
  if req_callback_url.length > 3
  	logger.info "Retrieving SR from remedy."

  	command = "'ruby script/runner ./jobs/aeroprise_sr_crud.rb #{login_name} #{sr_id} #{login_name} #{req_callback_url} #{worklog_callback_url}'"
  	
  	jobs = Bj::Table::Job.find(:all, :conditions => ["command LIKE ?", command])
		jobs.each do |job|
			if job.state == 'running' || job.state == 'pending'
				logger.info "pending request to fetch sr found, do nothing and return"
				return
			end
		end
		
		logger.info "submitting new request to fetch sr"
		Bj.submit command
	end
	
	logger.info "WARNING: returning with no action"
	return
end
    
# login as this user
api = login(login_name)
    
# get worklog and ping if there is any
workinfo = api.get_work_info(sr_id)
if api.error
	api.get_messages.each do |msg|
    loggger.debug "#{msg["type"]} : #{msg["num"]} : #{msg["text"]} "
  end
end
    
logger.debug workinfo.inspect.to_s

worklog = []
workinfo.each do |entry|
	record = {}
	record["submitter"] = entry["submitter"]
	record["type"] = entry["type"]
	record["summary"] = entry["summary"]
	record["notes"] = entry["notes"]
	record["submitdate"] = entry["submitdate"].to_s
  
	logger.debug record.inspect.to_s
      	
	worklog << record
end
    
if worklog.length > 0
	# serialize array of hashes and update
	wk_source = Source.find_by_name("AeropriseWorklog")
  ObjectValue.record_object_value(:object=>sr_id, :attrib=>"data",
  	:user_id=>user.id, :source_id=>wk_source.id, :value => RhomRecord.serialize(worklog))
      
  # ping the user
  user.ping(worklog_callback_url)
end
      
# flag request with so device will know to vibrate if required
if needs_attention == "TRUE"
	ObjectValue.record_object_value(:object=>sr_id, :attrib=>"needsattention",
		:user_id=>user.id, :source_id=>source.id, :value => "1")
	ObjectValue.record_object_value(:object=>sr_id, :attrib=>"vibrate",
		:user_id=>user.id, :source_id=>source.id, :value => "1")
	user.ping(req_callback_url)
end