class AeropriseApi < ActionWebService::API::Base
  api_method :sr_needs_attention, :expects => [{:login=>:string}, {:sr_id=>:string}], :returns => [:string]
  api_method :sr_work_info, :expects => [{:login=>:string}, {:instance_id =>:string}, {:sr_id=>:string}], :returns => [:string]
  api_method :srd_notification, :expects => [{:instance_id =>:string}, {:status =>:string}, {:active_state =>:string}], :returns => [:string]
end
