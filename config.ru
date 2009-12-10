require 'rubygems'
require 'sinatra'

Sinatra::Application.default_options.merge!(
:run => false,
:env => :production,
:raise_errors => true
)

require 'rhosync.rb'

RhosyncStore.add_adapter_path(File.join(File.dirname(__FILE__),'spec','adapters'))

run Sinatra::Application