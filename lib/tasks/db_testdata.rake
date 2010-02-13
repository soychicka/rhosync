require 'active_record/fixtures'

namespace :db do
  desc "bootstrap database with sample source adapters"
  task :bootstrap => 'db:fixtures:samples' do
  end
  
  namespace :fixtures do
    desc "load sample source adapters"
    task :samples => ['db:create','db:schema:load'] do
      Fixtures.create_fixtures(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'), 'sources')      
      Fixtures.create_fixtures(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'), 'apps')
      Fixtures.create_fixtures(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'), 'users')      
      Fixtures.create_fixtures(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'), 'administrations')
      Fixtures.create_fixtures(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'), 'configurations')
    end
  end
end
