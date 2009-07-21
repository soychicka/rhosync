require 'rho_base'
class RhoLarge < RhoBase
  def initialize(source,credential)
    super(source,credential)
    @baseurl = 'http://datafactory.heroku.com/data_tables/rholarge'
  end
end