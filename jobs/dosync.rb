source=Source.find 5
current_user=User.find 2
logger.debug "Calling sync for source "+source.name + " and user "+ current_user.login
source.dosync(current_user)