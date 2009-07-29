require 'rhobase'
class Rholarge < Rhobase
  def initialize(source,credential)
    super(source,credential)
  end
  def query
    @result = populate(50,1000)
  end
end