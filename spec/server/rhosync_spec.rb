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
set :views, File.join(File.dirname(__FILE__),'..','..','views')

require File.join(File.dirname(__FILE__),'..','..','rhosync.rb')

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
    post "/apps/#{@a.name}/client_login", "login" => @u.login, "password" => 'testpass'
    get '/'
    last_response.status.should == 200
  end

  describe "auth routes" do
    it "should login user with correct username,password" do
      post "/apps/#{@a.name}/client_login", "login" => @u.login, "password" => 'testpass'
      last_response.should be_ok
    end
    
    it "should respond 401 for incorrect username or password" do
      post "/apps/#{@a.name}/client_login", "login" => @u.login, "password" => 'wrongpass'
      last_response.status.should == 401
    end
  end
  
  describe "client management routes" do
    before(:each) do
      post "/apps/#{@a.name}/client_login", "login" => @u.login, "password" => 'testpass'
    end
    
    it "should respond to clientcreate" do
      get "/apps/#{@a.name}/clientcreate"
      last_response.should be_ok
      last_response.body.should == { "client" => { "client_id" => "2" } }.to_json
      Client.with_key(2).user_id.should == 'testuser'
    end
    
    it "should respond to clientregister" do
      post "/apps/#{@a.name}/clientregister", "device_type" => "iPhone", "client_id" => @c.id
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
      get "/apps/#{@a.name}/clientreset", :client_id => @c.id
      @store.get_data(doc1.get_key).should == {}
      @store.get_data(doc2.get_key).should == {}
    end
  end
  
  describe "source member routes" do
    before(:each) do
      post "/apps/#{@a.name}/client_login", "login" => @u.login, "password" => 'testpass'
      @fields = {
        :name => 'StorageAdapter',
        :url => 'http://example.com',
        :login => 'testuser',
        :password => 'testpass',
        :user_id => @u.id,
        :app_id => @a.id
      }
      @s = Source.create(@fields)
    end
    
    it "should post records for create" do
      @product1['_id'] = '1'
      params = {'create'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name}
      post "/apps/#{@a.name}", params
      last_response.should be_ok
      last_response.body.should == ''
      @store.get_data("test_create_storage").should == {'1'=>@product1}
    end
    
    it "should post records for update" do
      params = {'update'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name}
      post "/apps/#{@a.name}", params
      last_response.should be_ok
      last_response.body.should == ''
      @store.get_data("test_update_storage").should == {'1'=>@product1}
    end
    
    it "should post records for delete" do
      params = {'delete'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name}
      post "/apps/#{@a.name}", params
      last_response.should be_ok
      last_response.body.should == ''
      @store.get_data("test_delete_storage").should == {'1'=>@product1}
    end
    
    it "should get send_cud json" do
      cs = ClientSync.new(@s,@c,1)
      cs.process
      get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name
      last_response.should be_ok
      token = @store.get_value(cs.clientdoc.get_page_token_dockey)
      JSON.parse(last_response.body).should == {'token'=>token.to_s,'insert'=>{'1'=>{'foo'=>'bar'}}}
    end
  end
end