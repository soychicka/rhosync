# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem 'rubyist-aasm', :lib => 'aasm', :source => "http://gems.github.com"
  config.gem "httpclient"
  config.gem "soap4r", :lib => "soap/mapping"
  config.gem "uuidtools", :version => ">=2.0.0"
  config.gem "actionmailer",:lib => "actionmailer"
  config.gem "rspec", :lib => "spec"
  config.gem "rspec-rails", :lib => "spec/rake/spectask"
  config.gem "rcov"
  config.gem "libxml-ruby", :lib => "xml/libxml"
  config.gem "datanoise-actionwebservice", :lib => "actionwebservice", :version => "2.2.2"  
  config.gem "ar-extensions", :version => ">=0.9.2"
  config.gem "fastercsv"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # load source adapters, et al from here
  config.load_paths += Dir["#{RAILS_ROOT}/vendor/sync/*"]

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => 'rhosync_session',
    :secret      => '9d694d3f0150ddda62b8b8fc0e5397087abb91e39731f5a916df65203b242b587a29116cc02930929cd3c3c103853db756178f938e5b718afb6a20d86e85877c'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  config.active_record.observers = :user_observer

  config.active_record.colorize_logging = false
end

require 'ar-extensions/import/mysql' if Rails::Configuration.new.database_configuration[RAILS_ENV]["adapter"]=="mysql"

ActionController::Base.session_options[:session_expires] = 1.year.from_now

APP_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/settings.yml")[RAILS_ENV].symbolize_keys

begin
  ActiveRecord::ConnectionAdapters::MysqlAdapter::NATIVE_DATABASE_TYPES[:primary_key] = "BIGINT NOT NULL auto_increment PRIMARY KEY"
rescue
  
end
module SOAP
    SOAPNamespaceTag = 'env'
    XSDNamespaceTag = 'xsd'
    XSINamespaceTag = 'xsi'
end

RHOSYNC_LICENSE = IO.read("#{File.dirname(__FILE__)}/license.key").strip unless defined?(RHOSYNC_LICENSE)

