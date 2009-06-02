require 'open-uri'
class blackberry < Device
  
  attr_accessor :host,:serverport,:url,:devicepin,:deviceport
  
  def initialize(host="localhost",port=8080)
  end
  
  def notify  # don an iPhone-based push to the specified 
    open(self.url) do |f|
      f.each do |line|
        logger.debug "Response from notify: "+line
      end 
    end
  end
  
  def url
    @url="http"+ host +":" + @serverport + "/push?DESTINATION="+ @devicepin + "&PORT=" + @deviceport +"&REQUESTURI="+host
  end
end
