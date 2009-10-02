require 'sync'

class SourceAdapterException < RuntimeError
end

# raise this to cause client to be logged out during a sync
class SourceAdapterLoginException < SourceAdapterException; end

# raise these to trigger rhosync sending an error to the client
class SourceAdapterServerTimeoutException < SourceAdapterException; end

class SourceAdapterServerErrorException < SourceAdapterException; end

class SourceAdapter
  attr_accessor :client
  attr_accessor :qparms
  attr_accessor :session
    
  def initialize(source=nil,credential=nil)
    @source = source.nil? ? self : source
  end

  def login; end
  
  def query; end
  
  # this base class sync method now expects a (NEW IN 1.2) "Hash of Hashes generic results" structure.
  # specifically "generic results" is a hash of hashes.  The outer hash is the set of objects (keyed by the ID)
  # the inner hash is the set of attributes
  # you can choose to use or not use the parent class sync in your own RhoSync source adapters
  def sync
    return if result_nil? or result_empty?
    
    user_id = (usr = @source.current_user) ? usr.id : nil 

    default_sync = Sync::Synchronizer.new(@result, @source.id, @source.limit, user_id)
    default_sync.sync
  end
  
  def create(name_value_list)
  end

  def update(name_value_list); end

  def delete(name_value_list); end

  def logoff
  end
  
  # only implement this if you want RhoSync to install a callback into your backend
  # def set_callback(notify_url)
  # end
  
  
  MSG_NO_OBJECTS = "No objects returned from query"
  MSG_NIL_RESULT_ATTRIB = "You might have expected a synchronization but the @result attribute was 'nil'"
  
  #################################################
  private 
  def result_empty?
    Rails.logger.debug MSG_NO_OBJECTS if @result.empty? 
    @result.empty?
  end

  def result_nil?
    Rails.logger.warn MSG_NIL_RESULT_ATTRIB if @result.nil?
    @result.nil?
  end

end
