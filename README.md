Rhosync Data Cache
-------------------------------------------------------------

Redis-powered rhosync with built-in sinatra application. See rhosync.rb and "rake doc"
for information about required routes.

INSTALL
-------------------------------------------------------------
1. Make sure you have the following gems installed:

	rspec
	faker
	redis
	sinatra
	rack-test
	gem install relevance-rcov --source http://gems.github.com (make sure to uninstall rcov first)
	
2. Install and start a redis server (see http://code.google.com/p/redis/wiki/QuickStart)

3. "rake" to run all spec tasks, "rake doc" to see client/server protocol documentation

4. Checkout the API documentation: http://rdoc.info/projects/rhomobile/rhosync-datacache

TODO
-------------------------------------------------------------
* Refactor cud payload (c,u,d instead of create,update,delete), accept JSON post body
* Finish protocol documentation (rake doc) - needs errors,links
* Add version,count and maybe total_count
* Finish Sync States (client<->server<->backend)
* Add comments & DRYness to specs (refactor sample/storage adapters to run from db)
* Performance tests (ClientSync, SourceSync)
* Add queue layer for background adapters
* Installation scripts/process
* Management/Testing web console w/ import support
* Add uniqueness validation to app,client,user models
* Refactor User.is_exist? method (not very clean)