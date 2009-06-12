require 'net/http'
require 'uri'

# this class performs push to notify devices to retrieve data, all via BES server PAP push
# set APP_CONFIG['bbserver] in your settings.yml
class Blackberry < Device
  
  def set_ports    
    self.host=APP_CONFIG[:bbserver]  # make sure to set APP_CONFIG[:bbserver] in settings.yml
    self.host||="192.168.1.107"  # this is Lars' MDS server and shouldn't be hit. Change if you don't want to set APP_CONFIG[:bbserver]
    self.serverport="8080"
    self.deviceport||="100"
  end
  
  def ping(callback_url,message=nil,vibrate=nil) # notify the BlackBerry device via the BES server
    p "Pinging Blackberry device: #{pin}"
    set_ports
    
    @template =
<<-DESC
--asdlfkjiurwghasf
Content-Type: application/xml; charset=UTF-8

<?xml version="1.0"?>
<!DOCTYPE pap PUBLIC "-//WAPFORUM//DTD PAP 2.0//EN" 
  "http://www.wapforum.org/DTD/pap_2.0.dtd" 
  [<?wap-pap-ver supported-versions="2.0"?>]>
<pap>
<push-message push-id="pushID:--RAND_ID--" ppg-notify-requested-to="http://localhost:7778">

<address address-value="WAPPUSH=--DEVICE_PIN_HEX--%3A100/TYPE=USER@rim.net"/>
<quality-of-service delivery-method="confirmed"/>
</push-message>
</pap>
--asdlfkjiurwghasf
Content-Type: text/plain

--CONTENT--
--asdlfkjiurwghasf--
DESC
    
    @template.gsub!(/\n/,"\r\n")
    # begin
      data="do_sync="+callback_url+"\r\n"
      popup||=message # supplied message
      popup||=APP_CONFIG[:sync_popup]
      popup||="You have new data"
      popup=URI.escape(popup)
      (data = data + "show_popup="+ popup + "\r\n") if popup
      vibrate=APP_CONFIG[:sync_vibrate]
      (data = data + "vibrate="+vibrate.to_s) if vibrate
      post_body = @template
      post_body = post_body.gsub(/--RAND_ID--/, (rand * 100000000).to_i.to_s).gsub(/--DEVICE_PIN_HEX--/, self.pin.to_i.to_s(base=16).upcase).gsub(/--CONTENT--/, data)
      puts "POST_BODY: #{post_body.inspect}"
      headers={"X-WAP-APPLICATION-ID"=>"/",
               "X-RIM-PUSH-DEST-PORT"=>self.deviceport,
               "CONTENT-TYPE"=>'multipart/related; type="application/xml"; boundary=asdlfkjiurwghasf'}
      uri=URI.parse(url)
      p "URI: #{uri}"
      response = Net::HTTP.new(uri.host, uri.port).start do |http|
        request = Net::HTTP::Post.new(uri.path,headers)
        request.body = post_body
        http.request(request)
      end
      p "Result of BlackBerry PAP Push" + response.body  # log the results of the push
    # rescue
    #   p "Failed to push to BlackBerry device: "+ url + "=>" + $!
    # end
  end
  
  def url  # this is the logic for doing BES server PAP push.  Takes host & serverport
    if host and serverport
      @url="http://"+ host + "\:" + serverport + "/pap"
    else
      p "Do not have all values for URL"
      @url=nil
    end
  end
  
  # def ping(callback_url,message=nil,vibrate=nil) # notify the BlackBerry device via the BES server 
  #   p "Pinging Blackberry device: " + pin 
  #   set_ports 
  #   begin
  #     data="do_sync="+callback_url
  #     popup||=message # supplied message
  #     popup||=APP_CONFIG[:sync_popup]
  #     popup||="You have new data"
  #     popup=URI.escape(popup)
  #     (data = data + "&popup="+ popup) if popup
  #     vibrate=APP_CONFIG[:sync_vibrate]
  #     (data = data + "&vibrate="+vibrate.to_s) if vibrate
  #     headers={"X-RIM-PUSH-ID"=>push_id,"X-RIM-Push-NotifyURL"=>callback_url,"X-RIM-Push-Reliability-Mode"=>"APPLICATION"}
  #     #res = Net::HTTP.post(url,data,headers)  - this would have worked in Rails 1.2!!  they shouldnt have gotten rid of this call!
  #     uri=URI.parse(url)
  #     response=Net::HTTP.start(uri.host) do |http|
  #       request = Net::HTTP::Post.new(uri.path,headers)
  #       request.body = data
  #       response = http.request(request)
  #     end
  #     p "Result of BlackBerry PAP Push" + response.body[0..255]   # log the results of the push
  #   rescue
  #     p "Failed to push to BlackBerry device: "+ url + "=>" + $!
  #   end
  # end

  def push_id
    rand.to_s
  end
  
  # def url  # this is the logic for doing BES server PAP push.  Takes host, serverport, pin and deviceport
  #   if host and serverport and pin and deviceport
  #     @url="http://"+ host + "\:" + serverport + "/push?DESTINATION="+ pin + "&PORT=" + deviceport + "&REQUESTURI=" + host
  #   else
  #     p "Do not have all values for URL"
  #     @url=nil
  #   end
  # end
    

end
