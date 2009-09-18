set :deploy_to, "/mnt/apps/#{application}"
set :user, "www-data"
server "dev.rhosync.rhohub.com", :app, :web, :db, :primary => true

run "echo 'Setting production environment'"