require 'rhobase'
class Rhomedium < Rhobase
  def initialize(source,credential)
    super(source,credential)
  end
  def query
    @result = populate('rhomedium',25,1000)
  end
end