require 'sinatra/base'
require 'erb'
require 'rhosync_store'

module RhosyncStore
  class Server < Sinatra::Base
    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"
    enable :static, :raise_errors
    
    use Rack::Session::Cookie, :key => 'rhosync_session',
                               :path => '/',
                               :expire_after => 31536000,
                               :secret => 'b4990ed033389801c9ca1fe7844c07f9a719d48adc211f64412f53e7147ad2c36a36bcd334ccddc633a4ea6d35c2bbbeae1f6e3b833340a711e76edef734abee'

    log = File.new("log/rhosync.log", "a")
    $stdout.reopen(log)
    $stderr.reopen(log)
    
    helpers do
      def protected!
        response['WWW-Authenticate'] = %(Basic realm="Rhosync Auth") and \
        throw(:halt, [401, "Not authorized\n"]) and \
        return unless authorized?
      end

      def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
      end
    end
    
    get "/" do
      #protected!
      raise "die!"
    end
    
    # Collection routes
    post '/apps/:app_name/sources/client_login' do
      protected!
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
      protected!
      erb :show
    end
    
    post '/apps/:app_name/sources/:source_name' do
      status 200
    end
  end
end
