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
2. Install and start a redis server (see http://code.google.com/p/redis/wiki/QuickStart)
3. run "rake" to make sure all the specs pass
4. Checkout the API documentation: http://rdoc.info/projects/rhomobile/rhosync-datacache

TODO
-------------------------------------------------------------
* Finish ClientSync Scenarios (tokens, errors, CRUD)
* Add sinatra server
* Implement protocol
* Integration tests (client<->server<->backend)
* Performance tests (ClientSync, SourceSync)
* Add queue layer for background adapters
* Installation scripts/process