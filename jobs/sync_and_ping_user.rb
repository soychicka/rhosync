require File.join(File.dirname(__FILE__), '..', 'lib', 'source_adapter.rb')

logfile = File.open("log/bj-sync_and_ping.log", "a+")  
logger = Logger.new(logfile)

logger.debug "******* BEGIN *********"
logger.debug "#{Time.now} #{Process.pid} starting sync_and_ping_user #{ARGV.inspect.to_s}"

# usage: sync_and_ping_user.rb 2 AeropriseSrd http://rhosync.example.com/sources/10/show

current_user=User.find(ARGV[0])
source=Source.find_by_permalink(ARGV[1])
callback_url=ARGV[2]

logger.debug "current_user = #{current_user.inspect.to_s}"
logger.debug "source = #{source.inspect.to_s}"
logger.debug "callback_url = #{callback_url}"

logger.debug "current_user clients array="
current_user.clients.each {|d| logger.debug d.inspect.to_s}

begin
  source.dosync(current_user)
  result = current_user.ping(callback_url)
  logger.debug result.inspect.to_s
  logger.debug result.code
  logger.debug result.message
  logger.debug result.body
rescue SourceAdapterLoginException
  logger.debug "SourceAdapterLoginException, sending login failure to device"
  current_user.ping("", "login failed")
  # TODO: send specific message based on reason for failure
  
  # delete all other jobs for this user, otherwise we will get multiple login failures signalled to device
  ActiveRecord::Base.connection.execute("delete from bj_job where tag=#{current_user.id}")
  logger.debug "deleted all other jobs tagged with #{current_user.id}"
rescue => e
  logger.debug e.inspect.to_s
  logger.debug e.backtrace.join("\n")
end

logger.debug "... done sync_and_ping_user #{Time.now}"