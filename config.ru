require 'rubygems'
require 'sinatra'

set :run, false
set :environment, :production

require 'rhosync.rb'

RhosyncStore.add_adapter_path(File.join(File.dirname(__FILE__),'spec','adapters'))

FileUtils.mkdir_p 'log' unless File.exists?('log')
log = File.new("log/sinatra.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)

run Sinatra::Application