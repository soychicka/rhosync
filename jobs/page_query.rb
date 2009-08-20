# page_query.rb
# runs the paged query from the source adapter in background (BJ calls this script)
#one at a time until it gets a nil return
include SourcesHelper
logger = Logger.new("log/page_query.log")
logger.level=Logger::DEBUG
logger.debug "******* BEGIN *********"
logger.debug "#{Time.now} Starting page_query #{ARGV.inspect.to_s}"

# usage: page_query.rb <user number> <source number>
source=Source.find(ARGV[1])
source.current_user=User.find(ARGV[0])
logger.debug "source = #{source.inspect.to_s}"
logger.debug "current_user = #{source.current_user.inspect.to_s}"
source.backpages

logger.debug "... Done page_query at #{Time.now}"

