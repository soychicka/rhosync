class Product < SourceAdapter
  require 'json'
  require 'open-uri'
  require 'net/http'
  require 'uri'
  
  def initialize(source,credential)
    super(source,credential)
    #@baseurl="http://rhostore.heroku.com"
    @baseurl="http://localhost:3001"
  end
 
  def login
  end
 
  def query
    parsed=nil
    open(@baseurl+"/products.json") do |f|
      parsed=JSON.parse(f.read)
    end
    @result={}
    parsed.each {|item| @result[item["product"]["id"].to_s]=item["product"]}
    @result
  end
 
  def sync
    super
  end
 
  def create(name_value_list)
    attrvals={}
    name_value_list.each { |nv| attrvals["product["+nv["name"]+"]"]=nv["value"]} # convert name-value list to hash
    res = Net::HTTP.post_form(URI.parse("#{@baseurl}/products/create"),attrvals)  
    p res.body
  end
 
  def update(name_value_list)
    #TODO: write some code here
    # be sure to have a hash key and value for "object"
    raise "Please provide some code to update a single object in the backend application using the hash values in name_value_list"
  end
 
  def delete(name_value_list)
    #TODO: write some code here if applicable
    # be sure to have a hash key and value for "object"
    # for now, we'll say that its OK to not have a delete operation
    # raise "Please provide some code to delete a single object in the backend application using the hash values in name_value_list"
  end
 
  def logoff
    #TODO: write some code here if applicable
    # no need to do a raise here
  end
end