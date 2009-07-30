class AeropriseController < ApplicationController

  wsdl_service_name 'Aeroprise'
  web_service_api AeropriseApi
  web_service_scaffold :invocation if Rails.env == 'development'
  
  def notify(msg)
    "msg = "+ msg
  end
  
  def sr_needs_attention(login, sr_id)
    "OK sr_needs_attention stub"
  end
  
  def sr_work_info(login,instance_id,sr_id)
    "OK sr_work_info stub"
  end
  
  def srd_notification(instance_id, status, active_state)
    "OK srd_notification stub"
  end
end
