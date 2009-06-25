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
    @delegate && @delegate.public_method_defined?(:authenticate)
  end
  
  def authenticate(login, password)
    if @delegate && @delegate.authenticate(login, password)
      user = User.find_by_login(login)
      if !user
        user = User.create(:login => login, :password => "doesnotmatter", :password_confirmation => "doesnotmatter")
        self.users << user
      end
      return user
    end
  end
end
