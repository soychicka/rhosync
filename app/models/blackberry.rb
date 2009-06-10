require 'net/http'
require 'uri'

# this class performs push to notify devices to retrieve data, all via BES server PAP push
# set APP_CONFIG['bbserver] in your settings.yml
class Blackberry < Device
  
  def set_ports    
    self.host=APP_CONFIG[:bbserver]  # make sure to set APP_CONFIG[:bbserver] in settings.yml
    self.host||="192.168.10.77"  # this is our BES server and shouldn't be hit. Change if you dont want to set APP_CONFIG
    self.serverport=8080
    self.deviceport=100
  end
  
  def ping(callback_url) # notify the BlackBerry device via the BES server 
    p "Pinging Blackberry device: " + pin 
    set_ports 
    begin
      data="do_sync="+callback_url
      popup=APP_CONFIG[:sync_popup]
      popup||="You have new data"
      popup=URI.escape(popup)
      (data = data + "&popup="+ popup) if popup
      vibrate=APP_CONFIG[:sync_vibrate]
      (data = data + "&vibrate="+vibrate.to_s) if vibrate
      headers={"X-RIM-PUSH-ID"=>push_id,"X-RIM-Push-NotifyURL"=>callback_url,"X-RIM-Push-Reliability-Mode"=>"APPLICATION"}
      #res = Net::HTTP.post(url,data,headers)  - this would have worked in Rails 1.2!!  they shouldnt have gotten rid of this call!
      uri=URI.parse(url)
      response=Net::HTTP.start(uri.host) do |http|
        request = Net::HTTP::Post.new(uri.path,headers)
        request.body = data
        response = http.request(request)
      end
      p "Result of BlackBerry PAP Push" + response.body[0..255]   # log the results of the push
    rescue
      p "Failed to push to BlackBerry device: "+ url + "=>" + $!
    end
  end

  def push_id
    rand.to_s
  end
  
  def url  # this is the logic for doing BES server PAP push.  Takes host, serverport, pin and deviceport
    if host and serverport and pin and deviceport
      @url="http://"+ host + "\:" + serverport.to_s + "/push?DESTINATION="+ pin + "&PORT=" + deviceport.to_s + "&REQUESTURI=" + host
    else
      p "Do not have all values for URL"
      @url=nil
    end
  end
    

end
