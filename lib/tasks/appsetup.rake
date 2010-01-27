# setup applications

namespace :appsetup do
  
  desc "setup infusionsoft"
  task :infusionsoft => :environment do
    return if App.find_by_name("InfusionsoftCRM")
    
    app = App.create(:admin=>"admin", :name => "InfusionsoftCRM")
    user = User.find_by_login("admin")
    Administration.create(:app_id => app.id, :user_id => user.id)
    
    sources_table = <<-ETABLE 
      Contact            | InfusionsoftContacts        |        14400
      Note               | Infusionsoftnote            |        14400 
      Leadsource         | InfusionsoftLeadsources     |        14400 
      User               | InfusionsoftUsers           |        14400 
      Category           | InfusionsoftTagsCategories  |        14400 
      Tag                | InfusionsoftTags            |        14400 
      TagsAssign         | InfusionsoftTagsAssign      |        14400 
      Campaignees        | InfusionsoftCampaignees     |        14400 
      Campaign           | InfusionsoftCampaigns       |        14400
      CampaignStep       | InfusionsoftCampaignSteps   |        14400 
      ActionSeq          | InfusionsoftActionSeq       |        14400 
      ActionSeqAssign    | InfusionsoftActionSeqAssign |        14400 
      SavedSearches      | InfusionsoftSavedSearches   |        14400
    ETABLE

   sources_table.each_line do |source|
     values = source.split('|').each {|x| x.strip!}
     
     Source.create(:name=> values[0], :adapter => values[1], :app_id => app.id, :pollinterval=> values[2].to_i, :limit => 1000000)
   end    
  end

  desc "setup rhostore"
  task :rhostore => :environment do
    # do some useful stuff
  end
  
  desc "setup aeroprise"
  task :aeroprise => :environment do
  	if App.find_by_name("Aeroprise").nil?
	    app = App.create(:admin=>"admin", :name => "Aeroprise")
  	  user = User.find_by_login("admin")
    	Administration.create(:app_id => app.id, :user_id => user.id)
    
    	sources_table = <<-ETABLE 
      	AeropriseCategory   | AeropriseCategory |        -1
    	  AeropriseRequest    | AeropriseRequest  |        -1 
      	AeropriseSrd        | AeropriseSrd      |        -1 
      	AeropriseUser       | AeropriseUser     |        -1 
      	AeropriseWorklog    | AeropriseWorklog  |        -1 
    	ETABLE

   		sources_table.each_line do |source|
     		values = source.split('|').each {|x| x.strip!}
     		Source.create(:name=> values[0], :adapter => values[1], :app_id => app.id, :pollinterval=> values[2].to_i, :limit => 1000000)
   		end    
 		end
  end
end