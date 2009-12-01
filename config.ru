#!/usr/bin/env ruby
require 'logger'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/lib')
require 'rhosync_store/server'

use Rack::ShowExceptions
run RhosyncStore::Server.new