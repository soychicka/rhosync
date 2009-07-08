# == Schema Information
# Schema version: 20090624184104
#
# Table name: apps
#
#  id                 :integer(4)    not null, primary key
#  name               :string(255)   
#  admin              :string(255)   
#  description        :string(255)   
#  created_at         :datetime      
#  updated_at         :datetime      
#  anonymous          :integer(4)    
#  autoregister       :integer(4)    
#  stop_subscriptions :boolean(1)    
#

class App < ActiveRecord::Base
  has_many :sources
  has_many :users, :through=>:memberships # these are the users that are allowed to access the source for query, create, update, delete
  has_many :memberships
  has_many :administrations
  
  attr_accessor :delegate
  
  def after_initialize
    @delegate = name.constantize rescue nil
  end
  
  def to_param
    name.gsub(/[^a-z0-9]+/i, '-') unless new_record?
  end
  
  def self.find_by_permalink(link)
    App.find(:first, :conditions => ["id =:link or name =:link", {:link=> link}])
  end
  
  def authenticates?
    @delegate && @delegate.singleton_methods.include?("authenticate")
  end
  
  def authenticate(login, password, session)
    if @delegate && @delegate.authenticate(login, password, session)
      user = User.find_by_login(login)
      if !user
        user = User.create(:login => login, :password => "doesnotmatter", :password_confirmation => "doesnotmatter")
        self.users << user
      end
      return user
    end
  end
end
