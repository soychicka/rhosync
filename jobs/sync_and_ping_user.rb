# usage: sync_and_ping_user.rb TUser 10 http://rhosync.example.com/sources/10/show
current_user=User.find_by_login(ARGV[0])
source=Source.find(ARGV[1])
callback_url=ARGV[2]

source.dosync(current_user)
current_user.ping(callback_url)