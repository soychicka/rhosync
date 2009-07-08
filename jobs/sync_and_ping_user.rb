File.join(File.dirname(__FILE__), '..', 'lib', 'source_adapter.rb')

#logfile = File.open('log/bj-sync_and_ping.log', 'a')  
#Rails.logger = Logger.new(logfile)

# usage: sync_and_ping_user.rb TUser 10 http://rhosync.example.com/sources/10/show
current_user=User.find(ARGV[0])
source=Source.find_by_permalink(ARGV[1])
callback_url=ARGV[2]

Rails.logger.debug "****************"
Rails.logger.debug "#{Time.now} starting sync_and_ping_user #{ARGV.inspect.to_s}"
Rails.logger.debug "current_user = #{current_user.inspect.to_s}"
Rails.logger.debug "source = #{source.inspect.to_s}"
Rails.logger.debug "callback_url = #{callback_url}"

begin
  source.dosync(current_user)
  current_user.ping(callback_url)
rescue SourceAdapterLoginException
  current_user.ping(callback_url, "login failed")
end

Rails.logger.debug "... done sync_and_ping_user #{Time.now}"