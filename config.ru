require 'rubygems'
require 'sinatra'

require 'rhosync.rb'

RhosyncStore.add_adapter_path(File.join(File.dirname(__FILE__),'spec','adapters'))

run Sinatra::Application