require 'rhobase'
class Rhosmall < RhoBase
  def initialize(source,credential)
    super(source,credential)
    @baseurl = 'http://datafactory.heroku.com/data_tables/rhosmall'
  end
end