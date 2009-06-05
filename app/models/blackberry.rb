require 'open-uri'
class Blackberry < Device
  
  
  def set_ports    
    self.host=APP_CONFIG['bbserver']
    self.host||="192.168.10.77"
    self.serverport=8080
    self.deviceport=100
  end
  
  def ping  # do an iPhone-based push to the specified  device
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
  
  def url
    if host and serverport and pin and deviceport
      @url="http://"+ host + "\:" + serverport.to_s + "/push?DESTINATION="+ pin + "&PORT=" + deviceport.to_s + "&REQUESTURI=" + host
    else
      p "Do not have all values for URL"
      @url=nil
    end
  end
    

end
