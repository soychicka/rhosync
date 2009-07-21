require 'json'
require 'open-uri'

class RhoBase < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
  end
 
  def query
    parsed=nil
    open(@baseurl+"/showdata?format=json") do |f|
      parsed=JSON.parse(f.read)
    end
    @result={}
    parsed.each do |item|
      obj = item["id"].to_s
      @result[obj] = {}
      item.each do |key,val|
        unless key == 'id'
          element = {key => val}
          @result[obj].merge! element
        end
      end
    end
    @result
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
end