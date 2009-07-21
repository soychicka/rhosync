require 'rhobase'
class Rhomedium < RhoBase
  def initialize(source,credential)
    super(source,credential)
    @baseurl = 'http://datafactory.heroku.com/data_tables/rhomedium'
  end
end