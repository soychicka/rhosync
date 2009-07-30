require 'rhobase'
class Rhosmall < Rhobase
  def initialize(source,credential)
    super(source,credential)
  end
  def query
    @result = populate('rhosmall',50,100)
  end
end