require 'open-uri'

# this class performs push to notify devices to retrieve data, all via BES server PAP push
# set APP_CONFIG['bbserver] in your settings.yml
class Blackberry < Device
  
  def set_ports    
    self.host=APP_CONFIG['bbserver']  # make sure to set APP_CONFIG['bbserver']
    self.host||="192.168.10.77"  # this is our BES server and shouldn't be hit. Change if you dont want to set APP_CONFIG
    self.serverport=8080
    self.deviceport=100
  end
  
  def ping  # notify the BlackBerry device via the BES server 
    logger.debug "Pinging Blackberry device: " + pin 
    set_ports
    begin
      open(url) do |f|
        f.each do |line|
          logger.debug "Response from notify: "+line
        end 
      end
    rescue
      logger.debug "Failed to open URL: "+ url
    end
  end
  
  def url  # this is the logic for doing BES server PAP push.  Takes host, serverport, pin and deviceort
    if host and serverport and pin and deviceport
      @url="http://"+ host + "\:" + serverport.to_s + "/push?DESTINATION="+ pin + "&PORT=" + deviceport.to_s + "&REQUESTURI=" + host
    else
      p "Do not have all values for URL"
      @url=nil
    end
  end
    

end
