Rhosync Data Cache
-------------------------------------------------------------

This library is intended to provide a redis-powered data store for rhosync.

INSTALL
-------------------------------------------------------------
1. Make sure you have the following gems installed:

	rspec
	faker
	redis
2. Install and start a redis server (see http://code.google.com/p/redis/wiki/QuickStart)
3. run "rake" to make sure all the specs pass
4. Checkout the API documentation: http://rdoc.info/projects/rhomobile/rhosync-datacache

TODO
-------------------------------------------------------------
1. Cleanup class hierarchy (document, client_store, etc.)
2. Add queue layer for background adapters
3. Implement protocol
4. Finish ClientSync (tokens, errors)
5. Review store class
6. Add sinatra server