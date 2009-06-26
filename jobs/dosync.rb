source=Source.find ARGV[1]
current_user=User.find ARGV[0]
logger.debug "Calling sync for source "+source.name + " and user "+ current_user.login
source.dosync(current_user)