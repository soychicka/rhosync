class AeropriseApi < ActionWebService::API::Base
  api_method :notify, :expects => [{:msg=>:string}], :returns => [:string]
  api_method :sr_needs_attention, :expects => [{:login=>:string}, {:sr_id=>:string}], :returns => [:string]
end
