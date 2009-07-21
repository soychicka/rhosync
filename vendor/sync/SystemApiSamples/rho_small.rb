require 'rho_base'
class RhoSmall < RhoBase
  def initialize(source,credential)
    super(source,credential)
    @baseurl = 'http://datafactory.heroku.com/data_tables/rhosmall'
  end
end