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
Windows Notes: when run any spec task error message box (ruby.exe - Unable to locate component) will appear. Just press 'OK'. 
This is problem with relevance-rcov.

4. Checkout the API documentation: http://rdoc.info/projects/rhomobile/rhosync-datacache

TODO
-------------------------------------------------------------
* Implement search
* Finish Sync States (client<->server<->backend)
* Performance tests (ClientSync, SourceSync)
* Add queue layer for background adapters
* Installation scripts/process
* Administration web console
* Testing web console
* Import/Export support
* Add uniqueness validation to app,client,user models
* Refactor User.is_exist? method (not very clean)
* HTML protocol doc format