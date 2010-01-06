class AeropriseApi < ActionWebService::API::Base
  api_method :sr_crud, :expects => [{:login=>:string}, {:sr_id=>:string}, {:modified_by=>:string}], :returns => [:string]
  api_method :sr_work_info, :expects => [{:login=>:string}, {:instance_id =>:string}, {:sr_id=>:string}, {:needs_attention=>:string}], :returns => [:string]
  api_method :srd_notification, :expects => [{:instance_id =>:string}, {:status =>:string}, {:active_state =>:string}], :returns => [:string]
end
