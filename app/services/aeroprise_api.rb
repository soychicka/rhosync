class AeropriseApi < ActionWebService::API::Base
  api_method :notify, :expects => [{:msg=>:string}], :returns => [:string]
end
