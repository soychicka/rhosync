# dosync.rb  
#
include SourcesHelper

logfile = File.open("log/bj-dosync.log", "a+")  
logger = Logger.new(logfile)
logger.level=Logger::DEBUG
logger.debug "******* BEGIN *********"
logger.debug "#{Time.now} Starting dosync #{ARGV.inspect.to_s}"

# usage: page_query.rb <user number> <source number> <optional callback url>
source = Source.find(ARGV[1])
source.current_user = User.find(ARGV[0])
callback_url = ARGV[2] rescue nil

logger.debug "source = #{source.inspect.to_s}"
logger.debug "current_user = #{source.current_user.inspect.to_s}"
logger.debug "callback_url = #{callback_url}"

begin
  source.dosync(source.current_user)
  
  # now ping the user if there is a callback URL
  if callback_url
    logger.debug "pinging the current_user"

    result = source.current_user.ping(callback_url)
    logger.debug result.inspect.to_s  
  end
rescue => e
  logger.debug "Failed to call dosync"
  logger.debug "Exception: class: "+e.class.to_s+" : "+e.to_s
  logger.debug e.backtrace.join("\n")
end

logger.debug "******* END *********\dosync at #{Time.now}"

