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
  def populate(tbl,columnsize,rows)
    @res={}
    rows.times do |i|
      @res[tbl+i.to_s] = {}
      columnsize.times do |j|
        @res[tbl+i.to_s].merge!({"column#{j}" => "row#{i}-column#{j}"})
      end
    end
    @res
  end
end