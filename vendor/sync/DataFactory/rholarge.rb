require 'rhobase'
class Rholarge < Rhobase
  def initialize(source,credential)
    super(source,credential)
    @baseurl = 'http://datafactory.heroku.com/data_tables/rholarge'
  end
end