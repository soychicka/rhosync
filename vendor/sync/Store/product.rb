require 'rubygems'
require 'active_resource'
require 'rho_helper'
class Product < ActiveResource::Base
  include RhoHelper
  self.site = "http://rhostore.heroku.com/"
end