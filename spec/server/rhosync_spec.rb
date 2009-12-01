require File.join(File.dirname(__FILE__),'..','..','rhosync.rb')
require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

describe "Rhosync" do
  
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  it "should respond to /" do
    get '/'
    last_response.should be_ok
    last_response.body.should == 'Hello world'
  end
end