#
# This script is specific to Aeroprise application, and not a generally reuseable rhosync component
#

require 'rubygems'
#require 'rubyarapi'
#require 'aeroprise'
#require 'base64'

RAILS_ROOT=File.expand_path(File.dirname(__FILE__)+'/..')
require File.join(RAILS_ROOT, "config/environment")

#require 'aeroprise_srd'
#require 'aeroprise_srd_record'

#require File.join(File.dirname(__FILE__), '..', 'lib', 'source_adapter.rb')

logfile = File.open("log/bj-srd_runner.log", "a+")  
$logger = Logger.new(logfile)

def log_debug(msg)
  $logger.debug msg
  #puts msg
end

log_debug "#{Time.now} starting srd_runner #{ARGV.inspect.to_s}"

# usage: srd_runner.rb remove SRD_XXXXXXXXXXXX http://rhosync.example.com/sources/10/show

action        =ARGV[0]
srd_id        =ARGV[1]
callback_url  =ARGV[2]

log_debug "action = #{action}, srd_id=#{srd_id}, callback_url = #{callback_url}"

def ping(user, url)
  log_debug "pinging #{user.login}"
  result = user.ping(url)

  if result.blank?
    log_debug "empty result, failed"
  else
    log_debug result.inspect.to_s
    log_debug result.code
    log_debug result.message
    log_debug result.body
  end
  
  sleep 5
  rescue
  log_debug "exception in ping method wrapper"
end

begin
  app = App.find_by_name("Aeroprise")
  source = Source.find_by_name("AeropriseSrd")
  
  if action == 'add'
    serverip = app.configurations.find(:first, :conditions => {:name => 'remedyip'})
    adminuser = app.configurations.find(:first, :conditions => {:name => 'adminuser'})
    pw = app.configurations.find(:first, :conditions => {:name => 'adminpw'})
    
    raise "db config invalid" if adminuser.nil? || pw.nil?
    
    adminuser.value = Base64.decode64(adminuser.value)
    pw.value = Base64.decode64(pw.value)
    login,password = Aeroprise.decrypt(adminuser.value,pw.value)
    api = Rubyarapi.new(login,password,serverip.value)
    
    # iterate over all users
    log_debug "interating over #{app.users.size} users"
    app.users.each do |user|

      log_debug "impersonating #{user.login}"
      api.impersonate(user.login)
      
      # try to get this srd for them
      srd = api.get_srds(srd_id)
      log_debug "got this srd info #{srd.inspect.to_s}"
      
      # destroy all OLD OVAs for this user on the object
      ObjectValue.destroy_all(:source_id=>source.id, :update_type=>'query', :user_id => user.id, :object=>srd_id)
      
      if srd
        log_debug "adding srd to user's list"
        # re-add this srd to their data
        AeropriseBase.api=api
        AeropriseBase.logger = $logger
        AeropriseSrdRecord.create([srd_id, srd], source.id, user.id)

        # set them all to type query
        ObjectValue.update_all("update_type='query'", "object='#{srd_id}' and user_id=#{user.id} and source_id=#{source.id}")
      end
      
      #notify
      ping(user, callback_url)
    end
  elsif action == 'remove'
    # title is a required field for each srd, this gives us a row per SRD
    ovdata = ObjectValue.find(:all, :conditions => {:attrib=>"title", :source_id=>source.id, :update_type=>'query', :object=>srd_id})
    
    ovdata.each do |datum|
      user = datum.user
      
      # destroy all OVAs for this user on the object
      ObjectValue.destroy_all(:source_id=>source.id, :update_type=>'query', :user_id => user.id, :object=>datum.object)
      
      #notify
      ping(user, callback_url)
    end
  end

rescue => e
  log_debug e.inspect.to_s
  log_debug e.backtrace.join("\n")
end

log_debug "... done srd_runner"