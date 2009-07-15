class AeropriseController < ApplicationController

  wsdl_service_name 'Aeroprise'
  web_service_api AeropriseApi
  web_service_scaffold :invocation if Rails.env == 'development'
  
  def notify(msg)
    "msg = "+ msg
  end
  
  def sr_needs_attention(login, sr_id)
  end
end
