# page_query.rb
# runs the paged query from the source adapter in background (BJ calls this script)
#one at a time until it gets a nil return
include SourcesHelper
logger = Logger.new(STDOUT)
logger.level=Logger::DEBUG
logger.debug "******* BEGIN *********"
logger.debug "#{Time.now} Starting page_query #{ARGV.inspect.to_s}"

# usage: page_query.rb <user number> <source number>
current_user=User.find(ARGV[0])
source=Source.find(ARGV[1])

logger.debug "current_user = #{current_user.inspect.to_s}"
logger.debug "source = #{source.inspect.to_s}"

begin
  app=source.app
  usersub=app.memberships.find_by_user_id(current_user.id) if current_user
  source.credential=usersub.credential if usersub # this variable is available in your source adapter
  source_adapter=source.initadapter(source.credential,nil)
  pagenum=1  # zero-th page fetch is done by RhoSync server in foreground
  result=1
  while result 
    result=source_adapter.page(pagenum)
    source_adapter.sync
    id=source.id
    finalize_query_records(source.credential)
    pagenum=pagenum+1
  end
end

logger.debug "... Done page_query at #{Time.now}"

