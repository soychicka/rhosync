#
# This class is specific to Aeroprise application, and not a generally reuseable rhosync component
#

# these gems are not available in normal test env
unless RAILS_ENV=="test"
require 'rubyarapi'
require 'aeroprise'
end

class AeropriseController < ApplicationController

  wsdl_service_name 'Aeroprise'
  web_service_api AeropriseApi
  web_service_scaffold :invocation if Rails.env == 'development'
  
  # updates SR and toggle needs attention for it depending on login
  def sr_crud(login, sr_id, modified_by)	
  	command = "ruby script/runner ./jobs/aeroprise_sr_crud.rb #{login} #{sr_id} #{modified_by} #{app_source_url(:app_id => 'Aeroprise', :id => 'AeropriseRequest', :no_refresh=>true)} #{app_source_url(:app_id=>'Aeroprise', :id => 'AeropriseWorklog', :no_refresh=>true)}"
  	return queue_job(command, "sr_crud")
  end
  
  # loginID [Name of the aeroprise user]
  # instanceID [ID for current worklog entry]
  # SRInstanceID [ID for related SR]
  # needs_attention set flag in SR?
  def sr_work_info(login,instance_id,sr_id,needs_attention)
  	command = "ruby script/runner ./jobs/aeroprise_sr_work_info.rb #{login} #{sr_id} #{needs_attention} #{app_source_url(:app_id=>'Aeroprise', :id => 'AeropriseRequest', :no_refresh=>true)} #{app_source_url(:app_id=>'Aeroprise', :id => 'AeropriseWorklog', :no_refresh=>true)}"
  	return queue_job(command, "sr_work_info")
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
   # check for existing job in queue, and dont duplicate it
   def queue_job(job_string, job_code)
    jobs = Bj::Table::Job.find(:all, :conditions => {:command => job_string})
		jobs.each do |job|
			if job.state == 'running' || job.state == 'pending'
				logger.info "pending background job detected, skipping"
				return "OK #{job_code}"
			end
		end
  	
  	# queue new job
  	Bj.submit job_string
 
    "OK #{job_code}"
  rescue => e
    logger.info "exception while responding to WS #{job_code} #{e.inspect.to_s}"
    logger.info e.backtrace.join("\n")
    "ERROR #{job_code}"
  end
end
