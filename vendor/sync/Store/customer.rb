require 'json'
require 'open-uri'
class Customer < SourceAdapter
  def query(conditions=nil,limit=nil,offset=nil)
    logger = Logger.new('log/store.log', File::WRONLY | File::APPEND)
    logger.debug "query called with conditions=#{conditions} limit=#{limit} and offset=#{offset}"
    
    parsed=nil
    conditions=nil if conditions and conditions.size<1
    url="http://rhostore.heroku.com/customers.json"
    url=url+"?#{hashtourl(conditions)}" if conditions
    logger.debug "Searching with #{url}"
    open(url) do |f|
      parsed=JSON.parse(f.read)
    end
      logger.debug parsed.inspect.to_s
    @result={}
    
    parsed.each { |item|@result[item["customer"]["id"].to_s]=item["customer"] } if parsed
    
    logger.debug @result.inspect.to_s
    
    @result
  end
  
  def hashtourl(conditions)
    url=""
    first=true
    conditions.keys.each do |condition|
      if condition.length > 0
        url=url+"&" if not first
        url=url+"conditions[#{condition}]=#{conditions[condition]}"
        first=nil
      end
    end
    url
  end

  def page(num)
  	# return nil when we have exhausted the alphabet 
  	# returning nil will stop page method, {} does not
  	return nil if num>26
  	
    letter='A'
    num.times {letter=letter.next}
    if letter.size>1
      nil
    else
      p "Page #{letter}"
      parsed=nil
      open("http://rhostore.heroku.com/customers.json?firstletter=#{letter}") do |f|
        parsed=JSON.parse(f.read)
      end
      @result={}
      parsed.each { |item|@result[item["customer"]["id"].to_s]=item["customer"] } if parsed
      p "Result size: #{@result.size.to_s}"
      @result
    end
  end
 
  def sync
    # TODO: write code here that converts the data you got back from query into an @result object
    # where @result is an array of hashes,  each array item representing an object
    super # this creates object value triples from an @result variable that contains an array of hashes
  end
 
  def create(name_value_list)
    #TODO: write some code here
    # the backend application will provide the object hash key and corresponding value
    raise "Please provide some code to create a single object in the backend application using the hash values in name_value_list"
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