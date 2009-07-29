require 'json'
require 'open-uri'

class Rhobase < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
  end
 
  def query
  end
 
  def sync
    super
  end
 
  def create(name_value_list)
  end
 
  def update(name_value_list)
  end
 
  def delete(name_value_list)
  end
 
  def logoff
  end
  
  protected
  def populate(columnsize,rows)
    @res={}
    rows.times do |i|
      @res[i.to_s]={}
      columnsize.times do |j|
        @res[i.to_s] = {"column#{j}" => "row#{i}-column#{j}"}
      end
    end
    @res
  end
end