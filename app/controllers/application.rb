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
  
  after_filter :set_content_type
  
  def set_content_type
    response.content_type = Mime::HTML
  end

	after_filter :set_content_type

	def set_content_type
		response.content_type = Mime::HTML
  end

  # register this particular device and associated user as interested in queued sync
  def register_client(client)
    logger.debug 'Registering Client: ' + client.inspect
    if @current_user and not params["device_pin"].blank?
      client.pin = params["device_pin"]
      logger.debug "Registering device for notification with pin " + client.pin
      client.device_type=params["device_type"] if params["device_type"]  
      client.device_type||="Blackberry" # default to Blackberry 
      logger.debug "Device type is: " + client.device_type
      client.deviceport=params["device_port"] if params["device_port"]
      client.deviceport||="100"
      logger.debug "Device port is: " + client.deviceport
      client.save
    end
  end
  
  def find_and_register_client
    @client = Client.find_by_client_id(params[:client_id])
    if @client.nil?
    	logger.debug "creating new client"
    	@client = current_user.clients.build # we have to build first and get UUID generated
			@client.update_attributes(:client_id => params[:client_id]) # now update to one client is sending
    end
    
    register_client(@client)
  end
end
