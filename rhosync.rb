$:.unshift File.join(File.dirname(__FILE__),'lib')
require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'
require 'rhosync_store'

enable :static, :raise_errors

include RhosyncStore

use Rack::Session::Cookie, :key => 'rhosync_session',
                           :path => '/',
                           :expire_after => 31536000,
                           :secret => 'b4990ed033389801c9ca1fe7844c07f9a719d48adc211f64412f53e7147ad2c36a36bcd334ccddc633a4ea6d35c2bbbeae1f6e3b833340a711e76edef734abee'

configure :test do 
  add_adapter_path(File.join(File.dirname(__FILE__),'spec','adapters'))
end

helpers do
  def login_required
    current_user.nil?
  end
  
  def login
    user = User.authenticate(params[:login], params[:password])
    if user
      session[:login] = user.login
      true
    else
      false
    end
  end
  
  def logout
    session[:login] = nil
  end
  
  def current_user
    if User.is_exist?(session[:login])
      User.with_key(session[:login])
    end
  end
  
  def current_app
    App.with_key(params[:app_name]) if params[:app_name]
  end
  
  def current_source
    Source.with_key(params[:source_name]) if params[:source_name]
  end
  
  def current_client
    Client.with_key(params[:client_id]) if params[:client_id]
  end
end

before do
  unless request.env['PATH_INFO'].split('/').last == 'client_login'
    throw :halt, [401, "Not authenticated"] if login_required
  end
end

get "/" do
  erb :index
end

# Collection routes
post '/apps/:app_name/client_login' do
  logout
  if login
    status 200
  else
    status 401
  end
end

get '/apps/:app_name/clientcreate' do
  client = Client.create(:user_id => current_user.id)
  { "client" => { "client_id" =>  client.id.to_s } }.to_json
end

post '/apps/:app_name/clientregister' do
  current_client.device_type = params[:device_type]
  status 200
end

get '/apps/:app_name/clientreset' do
  ClientSync.reset(current_app,current_user,current_client)
  status 200
end

# Member routes
get '/apps/:app_name' do
  cs = ClientSync.new(current_source,current_client,params[:p_size])
  cs.send_cud(params[:token],params[:search]).to_json
end

post '/apps/:app_name' do
  cs = ClientSync.new(current_source,current_client,params[:p_size]) 
  cs.receive_cud(params)
  status 200
end
