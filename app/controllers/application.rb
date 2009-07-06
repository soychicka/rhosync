# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  # You can move this into a different controller, if you wish.  This module gives you the require_role helpers, and others.
  
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'cef446633dcc0a36bbb11791c172ffdc'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password
  
  
  def check_client   # check to see if this is a queued sync request, in which case register the device for the update
    @source=Source.find_by_permalink params[:id] if params[:id]
    register_client if @source 
  end
  # register this particular device and associated user as interested in queued sync
  def register_client
    if @current_user and not params["device_pin"].blank?
      @client=Client.find_or_create_by_pin params["device_pin"]
      if @client.user==nil   # device was not already registered
        logger.debug "Registering device for notification with pin " + @client.pin
        @client.user=@current_user
        @client.device_type=params["device_type"] if params["device_type"]  
        @client.device_type||="Blackberry" # default to Blackberry 
        logger.debug "Device type is: " + @client.device_type
        @client.deviceport=params["device_port"] if params["device_port"]
        @client.deviceport||="100"
        logger.debug "Device port is: " + @client.deviceport
        @client.save
      end
      existing=@current_user.clients.reject { |dvc| dvc.pin!=@client.pin}  # @current_user.clients has list of queued up devices for user
      @current_user.clients << @client if existing.size==0  # if there is no existing client with same pin add this new one

      existing=@source.users.reject { |user| user.id!=@current_user.id}  # @source.users has list of users queued up for pings
      @source.users<< @current_user if existing.size==0  # if not already in list 
      @source.callback_url=request.url # this stuffs the "show" method URL as the callback to be used by later pings
      args=request.url.index("\?")  # get rid of ? and beyond 
      if args and args>1
        @source.callback_url=@source.callback_url[0...args] # if its there
      end
      @source.save
    end
  end
  
end
