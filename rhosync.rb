require 'rubygems'
require 'sinatra'
require 'erb'
require 'json'

dir = File.dirname(File.expand_path(__FILE__))

enable :static, :raise_errors

use Rack::Session::Cookie, :key => 'rhosync_session',
                           :path => '/',
                           :expire_after => 31536000,
                           :secret => 'b4990ed033389801c9ca1fe7844c07f9a719d48adc211f64412f53e7147ad2c36a36bcd334ccddc633a4ea6d35c2bbbeae1f6e3b833340a711e76edef734abee'
helpers do
  def login_required
    current_user.nil?
  end

  def current_user
    if User.is_exist?(session[:login])
      User.with_key(session[:login])
    end
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
post '/apps/:app_name/sources/client_login' do
  logout
  if login
    status 200
  else
    status 401
  end
end

get '/apps/:app_name/sources/clientcreate' do
  @client = Client.create(:user_id => current_user.id)
  { "client" => { "client_id" =>  @client.id.to_s } }.to_json
end

post '/apps/:app_name/sources/clientregister' do
  @client = Client.with_key(params[:client_id])
  @client.device_type = params[:device_type]
  status 200
end

get '/apps/:app_name/sources/clientreset' do
  ClientSync.reset(App.with_key(params[:app_name]),
                   User.with_key(current_user.id),
                   Client.with_key(params[:client_id]))
  status 200
end

# Member routes
get '/apps/:app_name/sources/:source_name' do
  erb :show
end

post '/apps/:app_name/sources/:source_name' do
  status 200
end
