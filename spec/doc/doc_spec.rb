require File.join(File.dirname(__FILE__),'..','spec_helper')
require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'
require 'pp'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

require File.join(File.dirname(__FILE__),'..','..','rhosync.rb')

describe "Rhosync Protocol" do
  include Rack::Test::Methods
  include RhosyncStore
  
  Logger.enabled = false
  
  it_should_behave_like "SourceAdapterHelper"

  def app
    @app ||= Sinatra::Application
  end
  
  before(:each) do
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
  
  after(:each) do
    _print_messages
  end
  
  describe "unauthenticated routes - client_login" do
    it "end client_login" do
      do_post "/apps/#{@a.name}/client_login", "login" => @u.login, "password" => 'testpass'
    end
  end
  
  describe "unauthenticated routes - client_login with wrong login or password " do
    it "end wrong login or password client_login" do
      do_post "/apps/#{@a.name}/client_login", "login" => @u.login, "password" => 'wrongpass'
    end
  end
  
  describe "authenticated routes" do
    before(:each) do
      do_post "/apps/#{@a.name}/client_login", "login" => @u.login, "password" => 'testpass'
    end
    
    describe "- clientcreate" do
      it "end clientcreate" do 
        get "/apps/#{@a.name}/clientcreate"
      end
    end
    
    describe "- clientregister" do
      it "end clientregister" do
        do_post "/apps/#{@a.name}/clientregister", "device_type" => "iPhone", "client_id" => @c.id
      end
    end
    
    describe "- clientreset" do
      it "end clientreset" do
        get "/apps/#{@a.name}/clientreset", :client_id => @c.id
      end
    end
    
    describe "- client create object(s)" do
      it "end client create object(s)" do
        params = {'create'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name}
        do_post "/apps/#{@a.name}", params
      end
    end
    
    describe "- client update object(s)" do
      it "end client update object(s)" do
        params = {'update'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name}
        do_post "/apps/#{@a.name}", params        
      end
    end
    
    describe "- client delete object(s)" do
      it "end client delete object(s)" do
        params = {'delete'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name}
        do_post "/apps/#{@a.name}", params
      end
    end 
    
    describe "- client create,update,delete objects" do
      it "end client create,update,delete objects" do
        params = {'create'=>{'1'=>@product1},
                  'update'=>{'2'=>@product2},
                  'delete'=>{'3'=>@product3},
                  :client_id => @c.id,
                  :source_name => @s.name}
        do_post "/apps/#{@a.name}", params
      end
    end
    
    describe "- server send insert objects to client" do
      it "end server send insert objects to client" do
        cs = ClientSync.new(@s,@c,1)
        injection = {'1'=>@product1,'2'=>@product2}
        @store.put_data('test_db_storage',injection)
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name
      end
    end
    
    describe "- server send delete objects to client" do
      it "end server send delete objects to client" do 
        cs = ClientSync.new(@s,@c,1)
        injection = {'1'=>@product1,'2'=>@product2}
        @store.put_data('test_db_storage',injection)
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name
        token = @store.get_value(cs.clientdoc.get_page_token_dockey)
        @store.flash_data('test_db_storage')
        @s.refresh_time = Time.now.to_i
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token
      end
    end
    
    describe "- server send insert,delete objects to client" do
      it "end server send insert,delete objects to client" do 
        cs = ClientSync.new(@s,@c,1)
        injection = {'1'=>@product1,'2'=>@product2}
        @store.put_data('test_db_storage',injection)
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name
        token = @store.get_value(cs.clientdoc.get_page_token_dockey)
        @store.put_data('test_db_storage',{'1'=>@product1,'3'=>@product3})
        @s.refresh_time = Time.now.to_i
        get "/apps/#{@a.name}",:client_id => @c.id,:source_name => @s.name,:token => token
      end
    end
  end
  
  private
  def _print_messages
    method = last_request.env['REQUEST_METHOD']
    query_string = last_request.env['QUERY_STRING'].empty? ? '' : "?#{last_request.env['QUERY_STRING']}"
    body = last_request.body.read
    response_body = last_response.body
    puts '-'*25 + 'REQUEST' + '-'*25
    puts "METHOD URL: #{method} #{last_request.env['PATH_INFO']}#{query_string}"
    puts '-'*57
    puts "Request Headers: "
    puts ' "Content-Type"=>' + last_request.env['CONTENT_TYPE'].inspect unless method == 'GET'
    puts ' "Content-Length"=>' + last_request.env['CONTENT_LENGTH'].inspect unless method == 'GET'
    puts ' "Cookie"=>' + last_request.env['HTTP_COOKIE'].inspect
    if not body.empty?
      puts "Request Body:"
      puts body
    end
    puts '-'*25 + 'RESPONSE' + '-'*24
    puts "Response Headers: "
    pp last_response.headers
    puts "Response Status: " + last_response.status.to_s
    if not response_body.empty?
      puts "Response body: "
      puts response_body
    end
  end
end