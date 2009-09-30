# == Schema Information
# Schema version: 20090921184016
#
# Table name: clients
#
#  client_id       :string(36)    primary key
#  session         :string(255)   
#  created_at      :datetime      
#  updated_at      :datetime      
#  user_id         :integer(4)    
#  last_sync_token :string(255)   
#  device_type     :string(255)   
#  carrier         :string(255)   
#  manufacturer    :string(255)   
#  model           :string(255)   
#  pin             :string(255)   
#  host            :string(255)   
#  serverport      :string(255)   
#  deviceport      :string(255)   
#

require 'net/http'
require 'uri'

class Blackberry < Client
  
  def ping(callback_url,message=nil,vibrate=nil,badge=nil,sound=nil) # notify the BlackBerry device via PAP
    logger.debug "Pinging Blackberry device via BES push: " + pin 
    set_ports
    setup_template
    data=build_payload(callback_url,message,vibrate)
    headers={"X-WAP-APPLICATION-ID"=>"/",
             "X-RIM-PUSH-DEST-PORT"=>self.deviceport,
             "CONTENT-TYPE"=>'multipart/related; type="application/xml"; boundary=asdlfkjiurwghasf'}
    logger.debug "SELF ------- #{self.inspect}"
    begin
      @result=http_post(url,data,headers)   
      Rails.logger.debug "Returning #{@result.inspect}"
Rails.logger.debug @result.body

    rescue
      Rails.logger.debug "Failed to post "
      @result="post failure"
    end
    @result
  end
  
  private
  
  def set_ports    
    self.host||=APP_CONFIG[:bbserver]  # make sure to set APP_CONFIG[:bbserver] in settings.yml
    self.serverport||="8080"
    self.deviceport||="100"
  end

  def http_post(address,data,headers)
    uri=URI.parse(address)
    logger.debug "URI: #{uri}"
    response=Net::HTTP.new(uri.host,uri.port).start do |http|
      request = Net::HTTP::Post.new(uri.path,headers)
      request.body = data

Rails.logger.debug "*******"
Rails.logger.debug data
Rails.logger.debug "*******"

      http.request(request)
    end
    response
  end

  def build_payload(callback_url,message,vibrate)
    setup_template
    data=""
    # warning: sending "" as do_sync will sync all sources
    if (!callback_url.blank?)
      data = "do_sync=#{callback_url}\r\n"
    end
    popup = (message || APP_CONFIG[:sync_popup])
    (data = data + "show_popup="+ popup + "\r\n") if !popup.blank?
    vibrate=APP_CONFIG[:sync_vibrate]
    (data = data + "vibrate="+vibrate.to_s) if vibrate
    post_body = @template
    post_body.gsub(/--RAND_ID--/, push_id).gsub(/--DEVICE_PIN_HEX--/, self.pin.to_i.to_s(base=16).upcase).gsub(/--CONTENT--/, data)
  end
  
  def push_id
    (rand * 100000000).to_i.to_s
  end
  
  def setup_template
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
<quality-of-service delivery-method="preferconfirmed"/>
</push-message>
</pap>
--asdlfkjiurwghasf
Content-Type: text/plain

--CONTENT--
--asdlfkjiurwghasf--
DESC
    @template.gsub!(/\n/,"\r\n")
  end
  
  def url  # this is the logic for doing BES server PAP push.  Takes host & serverport\
    if host and serverport
      @url="http://"+ host + "\:" + serverport + "/pap"
    else
      p "Do not have all values for URL"
      @url=nil
    end
  end
  
  def push_id
    (rand * 100000000).to_i.to_s
  end
end
