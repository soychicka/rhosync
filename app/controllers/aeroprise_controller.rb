#
# This class is specific to Aeroprise application, and not a generally reuseable rhosync component
#

require 'rubyarapi'
require 'aeroprise'
require 'base64'
require 'crypt/blowfish'

class AeropriseController < ApplicationController

  wsdl_service_name 'Aeroprise'
  web_service_api AeropriseApi
  web_service_scaffold :invocation if Rails.env == 'development'
  
  def record_object_value(oav)
    ovdata = ObjectValue.find(:first, :conditions => {:object=>oav[:object], :attrib=>oav[:attrib],
        :user_id=>oav[:user_id], :source_id=>oav[:source_id]})
    
    if ovdata
      ovdata.delete
    end
    
    ObjectValue.create(:object=>oav[:object], :attrib=>oav[:attrib],
        :user_id=>oav[:user_id], :source_id=>oav[:source_id], :value => oav[:value], :update_type=>"query")    
  end
  
  def sr_needs_attention(login, sr_id)
    # toggle needs attention for this SR
    @source = Source.find_by_name("AeropriseRequest")
    @user = User.find_by_login(login)
    
    record_object_value(:object=>sr_id, :attrib=>"needsattention",
        :user_id=>@user.id, :source_id=>@source.id, :value => "1")

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
     
    # find the user for this SR
    user_id = ObjectValue.find(:first, :conditions => {:object=>sr_id, :attrib=>"user_id",
        :source_id=>@source.id}).value
        
    # TBD: there is no object that matches!
    
    # login as this user
    api = login(user_id)
    
    # worklog info
    workinfo = api.get_work_info(sr_id)

    worklog = []
    workinfo.each do |entry|
      record = {}
      record["submitter"] = entry["submitter"]
      record["type"] = entry["type"]
      record["summary"] = entry["summary"]
      record["notes"] = entry["notes"]
      record["submitdate"] = entry["submitdate"]
      worklog << record
    end

    user = User.find_by_login(user_id)
    
    # serialize array of hashes and update 
    record_object_value(:object=>sr_id, :attrib=>"workinfo",
      :user_id=>user.id, :source_id=>@source.id, :value => RhomRecord.serialize(worklog))
    
    # ping the user
    result = user.ping(app_source_url(:app_id=>@source.app.name, :id => @source.name))
    logger.debug result.inspect.to_s
    logger.debug result.code
    logger.debug result.message
    logger.debug result.body
    
    "OK sr_work_info"
  rescue => e
    logger.debug "exception while responding to WS sr_work_info #{e.inspect.to_s}"
    logger.debug e.backtrace.join("\n")
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
        Bj.submit "ruby script/runner ./jobs/srd_runner.rb add #{instance_id} #{app_source_url(:app_id=>"Aeroprise", :id => @source.name)}"
      end
    end
    
    # if expired or offline, check if present. if so, remove and notify
    if (status=='expired' || active_state=='offline')
      if @srd
        # start background job to try to remove this SRD for each user that has it
        Bj.submit "ruby script/runner ./jobs/srd_runner.rb remove #{instance_id} #{app_source_url(:app_id=>"Aeroprise", :id => @source.name)}"
      end
    end
        
    "OK srd_notification"
  rescue => e
    logger.debug "exception while responding to WS srd_notification #{e.inspect.to_s}"
    logger.debug e.backtrace.join("\n")
    "ERROR srd_notification"
  end
  
 
 protected
 
  def login(user_login)
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
      admin_user.value = Base64.decode64(user.value)
      pw.value = Base64.decode64(pw.value)
      
      login,password = Aeroprise.decrypt(admin_user.value,pw.value)
    else
      login,password = "Demo",""
    end

    api = Rubyarapi.new(login,password,serverip,serverport)
    
    api.impersonate(user_login) # the user we are impersonating
    api.get_user_info
      if api.error
        raise "admin login failure" 
       end
    
    logger.debug "login succeeded"
    api
  end
end
