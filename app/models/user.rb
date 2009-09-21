# == Schema Information
# Schema version: 20090624184104
#
# Table name: users
#
#  id                        :integer(4)    not null, primary key
#  login                     :string(40)    
#  name                      :string(100)   default("")
#  email                     :string(100)   
#  crypted_password          :string(40)    
#  salt                      :string(40)    
#  created_at                :datetime      
#  updated_at                :datetime      
#  remember_token            :string(40)    
#  remember_token_expires_at :datetime      
#  password_reset_code       :string(255)   
#  expires_at                :datetime      
#

require 'digest/sha1'
require 'rubygems'
require 'aasm'
class User < ActiveRecord::Base
  has_many :apps, :through=>:memberships
  has_many :memberships
  has_many :administrations
  has_many :clients
  has_many :synctasks
  has_many :users
  has_many :source_notifies
  has_many :object_values
  has_many :sources, :through => :source_notifies
  
  include Authentication
  
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
  def ping(callback_url,message=nil,vibrate=500,badge=nil,sound=nil)
    @result=""
    clients.each do |client|
      # will fail if client.device_type is blank
      @result=client.ping(callback_url,message,vibrate,badge,sound)
      p "Result of client ping: #{@result}" if @result
    end
    @result
  end 
end
