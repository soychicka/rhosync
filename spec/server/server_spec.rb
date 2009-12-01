$:.unshift File.join(__FILE__,'..','..','lib')
require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'
require 'rhosync_store/server'

# set test environment
set :environment, :test

describe "Server" do
  include Rack::Test::Methods
  
  def app
    @app ||= RhosyncStore::Server
  end
  
  it "should respond to /" do
    puts "inside test"
    get '/'
    last_response.should be_ok
  end
  
  
end