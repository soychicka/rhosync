require File.join(File.dirname(__FILE__),'..','..','rhosync.rb')
require File.join(File.dirname(__FILE__),'..','spec_helper')
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
  include RhosyncStore
  
  it_should_behave_like "SourceAdapterHelper"

  def app
    @app ||= Sinatra::Application
  end
  
  it "should respond with 401 to /" do
    get '/'
    last_response.status.should == 401
  end

  it "should respond with 200 if logged in" do
    post "/apps/#{@a.name}/sources/client_login", "login" => @u.login, "password" => 'testpass'
    get '/'
    last_response.status.should == 200
  end

  describe "auth routes" do
    it "should login user with correct username,password" do
      post "/apps/#{@a.name}/sources/client_login", "login" => @u.login, "password" => 'testpass'
      last_response.should be_ok
    end
    
    it "should respond 401 for incorrect username or password" do
      post "/apps/#{@a.name}/sources/client_login", "login" => @u.login, "password" => 'wrongpass'
      last_response.status.should == 401
    end
  end
  
  describe "client management routes" do
    
    before(:each) do
      post "/apps/#{@a.name}/sources/client_login", "login" => @u.login, "password" => 'testpass'
    end
    
    it "should respond to clientcreate" do
      get "/apps/#{@a.name}/sources/clientcreate"
      last_response.should be_ok
      last_response.body.should == { "client" => { "client_id" => "2" } }.to_json
      Client.with_key(2).user_id.should == 'testuser'
    end
    
    it "should respond to clientregister" do
      post "/apps/#{@a.name}/sources/clientregister", "device_type" => "iPhone", "client_id" => @c.id
      last_response.should be_ok
      last_response.body.should == ''
      @c.device_type.should == 'iPhone'
      @c.id.should == 1
    end
    
    it "should respond to clientreset" do
      doc1 = Document.new('cd',@a.id,@u.id,@c.id,'source1')
      doc2 = Document.new('cd',@a.id,@u.id,@c.id,'source2')
      @store.put_data(doc1.get_key,@data)
      @store.put_data(doc2.get_key,@data)
      get "/apps/#{@a.name}/sources/clientreset", :client_id => @c.id
      @store.get_data(doc1.get_key).should == {}
      @store.get_data(doc2.get_key).should == {}
    end
  end
end