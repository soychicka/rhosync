#
# This script is specific to Aeroprise application, and not a generally reuseable rhosync component
#

require 'rubyarapi'
require 'aeroprise'
require 'base64'
require 'aeroprise_srd'
require 'aeroprise_srd_record'

File.join(File.dirname(__FILE__), '..', 'lib', 'source_adapter.rb')

logfile = File.open("log/bj-srd_runner.log", "a+")  
logger = Logger.new(logfile)

logger.debug "#{Time.now} starting srd_runner #{ARGV.inspect.to_s}"

# usage: srd_runner.rb remove SRD_XXXXXXXXXXXX http://rhosync.example.com/sources/10/show

action        =ARGV[0]
srd_id        =ARGV[1]
callback_url  =ARGV[2]

logger.debug "action = #{action}, srd_id=#{srd_id}, callback_url = #{callback_url}"

def ping(user)
  result = user.ping(callback_url)

  logger.debug result.inspect.to_s
  logger.debug result.code
  logger.debug result.message
  logger.debug result.body
  
  sleep 5
end

begin
  app = App.find_by_name("Aeroprise")
  source = Source.find_by_name("AeropriseSrd")
  
  if action == 'add'
    
    serverip = app.configurations.find(:first, :conditions => {:name => 'remedyip'})
    adminuser = app.configurations.find(:first, :conditions => {:name => 'adminuser'})
    pw = app.configurations.find(:first, :conditions => {:name => 'adminpw'})
    adminuser.value = Base64.decode64(adminuser.value)
    pw.value = Base64.decode64(pw.value)
    login,password = Aeroprise.decrypt(adminuser.value,pw.value)
    api = Rubyarapi.new(login,password,serverip)
    
    # iterate over all users
    app.users.each do |user|

      api.impersonate(user.login)
      
      # try to get this srd for them
      srd = api.get_srds(srd_id)
      
      # destroy all OLD OVAs for this user on the object
      ObjectValue.destroy_all(:source_id=>source.id, :update_type=>'query', :user_id => user.id, :object=>srd_id)
      
      # re-add this srd to their data
      AeropriseSrdRecord.create(srd, source.id, user.id) if srd
      
      #notify
      ping(user)
    end
  elsif action == 'remove'
    # title is a required field for each srd, this gives us a row per SRD
    ovdata = ObjectValue.find(:all, :conditions => {:attrib=>"title", :source_id=>source.id, :update_type=>'query', :object=>srd_id})
    
    ovdata.each do |datum|
      user = datum.user
      
      # destroy all OVAs for this user on the object
      ObjectValue.destroy_all(:source_id=>source.id, :update_type=>'query', :user_id => user.id, :object=>datum.object)
      
      #notify
      ping(user)
    end
  end

rescue => e
  logger.debug e.inspect.to_s
  logger.debug e.backtrace.join("\n")
end

logger.debug "... done srd_runner"