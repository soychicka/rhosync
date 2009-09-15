# page_query.rb  
# runs the paged query from the source adapter in background (BJ calls this script)
#one at a time until it gets a nil return
include SourcesHelper
logger = Logger.new(STDOUT)
logger.level=Logger::DEBUG
logger.debug "******* BEGIN *********"
logger.debug "#{Time.now} Starting page_query #{ARGV.inspect.to_s}"

# usage: page_query.rb <user number> <source number> [start page (defaults to 1)]
source=Source.find(ARGV[1])
source.current_user=User.find(ARGV[0])
logger.debug "Source = #{source.inspect.to_s}"
logger.debug "Current_user = #{source.current_user.inspect.to_s}"
begin
  source.backpages startpage
rescue
  logger.debug "Failed to call backpages"
end
logger.debug "Done page_query at #{Time.now}"

