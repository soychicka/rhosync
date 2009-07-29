require 'rhobase'
class Rhomedium < Rhobase
  def initialize(source,credential)
    super(source,credential)
  end
  def query
    @result = populate(25,100)
  end
end