require 'rubygems'
require 'sinatra'
require 'erb'

dir = File.dirname(File.expand_path(__FILE__))

enable :static, :raise_errors

use Rack::Session::Cookie, :key => 'rhosync_session',
                           :path => '/',
                           :expire_after => 31536000,
                           :secret => 'b4990ed033389801c9ca1fe7844c07f9a719d48adc211f64412f53e7147ad2c36a36bcd334ccddc633a4ea6d35c2bbbeae1f6e3b833340a711e76edef734abee'

get "/" do
  erb :index
end

# Collection routes
post '/apps/:app_name/sources/client_login' do
  status 200
end

get '/apps/:app_name/sources/clientcreate' do
  erb :clientcreate
end

post '/apps/:app_name/sources/clientregister' do
  status 200
end

get '/apps/:app_name/sources/clientreset' do
  status 200
end

# Member routes
get '/apps/:app_name/sources/:source_name' do
  erb :show
end

post '/apps/:app_name/sources/:source_name' do
  status 200
end
