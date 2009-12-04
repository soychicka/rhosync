Rhosync Data Cache
-------------------------------------------------------------

This library is intended to provide a redis-powered data store for rhosync.

INSTALL
-------------------------------------------------------------
1. Make sure you have the following gems installed:

	rspec
	faker
	redis
	sinatra
	rack-test
	relevance-rcov (make sure to uninstall rcov first due to known memory issues)
	
2. Install and start a redis server (see http://code.google.com/p/redis/wiki/QuickStart)

3. run "rake" to make sure all the specs pass

4. Checkout the API documentation: http://rdoc.info/projects/rhomobile/rhosync-datacache

NOTE: Run "rm -rf tmp coverage" before each run of "rake spec" or "rake all"

TODO
-------------------------------------------------------------
* Add source timeout
* Finish ClientSync Scenarios (tokens, errors, CRUD)
* Add sinatra server
* Implement protocol
* Finish Sync States (client<->server<->backend)
* Performance tests (ClientSync, SourceSync)
* Add queue layer for background adapters
* Installation scripts/process
* Management/Testing web console w/ import support
* Add uniqueness validation to app,client,user models
* Refactor User.is_exist? method (not very clean)
* Fix Rakefile spec tasks
