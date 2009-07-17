class Camera < SourceAdapter
  PATH = File.join(RAILS_ROOT,'public','images')
  
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
  end
 
  def query
    @result={}
    Dir.entries(PATH).each do |entry|
      puts "Entry: #{entry.inspect}"
      new_item = {'image_uri' => 'http://dev.rhosync.rhohub.com/images/'+entry}
      @result[entry.hash.to_s] = new_item unless (entry == '..' || entry == '.' || entry == '.keep')
    end
    puts "@result: #{@result.inspect}"
    @result
  end
 
  def sync
    super
  end
 
  def create(name_value_list,blob)
    if blob
      obj = ObjectValue.find(:first, :conditions => "object = '#{blob.instance.object}' AND value = '#{name_value_list[0]["value"]}'")
      path = blob.path.gsub(/\/\//,"\/#{obj.id}\/")
      name = name_value_list[0]["value"]
    
      `cp #{path} #{File.join(PATH,name)}`
    end
  end
 
  def update(name_value_list)
  end
 
  def delete(name_value_list)
    
  end
 
  def logoff
  end
end