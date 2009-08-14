#
# This class is specific to Aeroprise application, and not a generally reuseable rhosync component
#

class AeropriseController < ApplicationController

  wsdl_service_name 'Aeroprise'
  web_service_api AeropriseApi
  web_service_scaffold :invocation if Rails.env == 'development'
  
  def sr_needs_attention(login, sr_id)
    # toggle needs attention for this SR
    @source = Source.find_by_name("AeropriseRequest")
    @user = User.find_by_login(login)
    
    ovdata = ObjectValue.find(:first, :conditions => {:object=>sr_id, :attrib=>"needsattention",
        :user_id=>@user.id, :source_id=>@source.id})
    if ovdata
      ovdata.update_attribute(:value, "1")
    else
      ObjectValue.create(:object=>sr_id, :attrib=>"needsattention",
        :user_id=>@user.id, :source_id=>@source.id, :value => "1", :update_type=>"query")
    end
     
    # ping the user
    result = @user.ping(app_source_url(:app_id=>@source.app.name, :id => @source.name))
    logger.debug result.inspect.to_s
    logger.debug result.code
    logger.debug result.message
    logger.debug result.body
    
    "OK sr_needs_attention"
  rescue =>e
    logger.debug "exception while responding to WS sr_needs_attention\n #{e.inspect.to_s}"
    logger.debug e.backtrace.join("\n")
    "ERROR sr_needs_attention"
  end
  
  # loginID [Name of the aeroprise user]
  # instanceID [ID for current worklog entry]
  # SRInstanceID [ID for related SR]
  def sr_work_info(login,instance_id,sr_id)
    @source = Source.find_by_name("AeropriseRequest")
    @user = User.find_by_login(login)
     
    # get the updated worklog info for this SR
 
    
    # ping the user
    
    "OK sr_work_info"
  rescue
    "ERROR sr_work_info"
  end
  
  # instanceID [ID for SRD]
  # Status [Current state of SRD two main values 'deployed' and 'expired']
  # activeState [Whether or not the SRD is 'online' or 'offline']
  def srd_notification(instance_id, status, active_state)
    @source = Source.find_by_name("AeropriseSrd")
    @srd = ObjectValue.find(:first, :conditions => {:object=>instance_id, :source_id=>@source.id})

    # if deployed and online, check if present. if not add and notify
    if (status=='deployed' && active_state=='online')
      if @srd.nil?
        # start background job to try to get this SRD for each user
        Bj.submit "ruby script/runner ./jobs/srd_runner.rb add #{instance_id} #{app_source_url(:app_id=>@app.name, :id => @source.name)}"
      end
    end
    
    # if expired or offline, check if present. if so, remove and notify
    if (status=='expired' || active_state=='offline')
      if @srd
        # start background job to try to remove this SRD for each user that has it
        Bj.submit "ruby script/runner ./jobs/srd_runner.rb remove #{instance_id} #{app_source_url(:app_id=>@app.name, :id => @source.name)}"
      end
    end
        
    "OK srd_notification"
  rescue
    "ERROR srd_notification"
  end
end
