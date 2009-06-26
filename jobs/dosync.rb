source=Source.find ARGV[1]
current_user=User.find ARGV[0]
source.dosync(current_user)