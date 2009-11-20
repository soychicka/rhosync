module RhosyncStore
  class SourceAdapterException < RuntimeError; end

  # raise this to cause client to be logged out during a sync
  class SourceAdapterLoginException < SourceAdapterException; end

  # raise these to trigger rhosync sending an error to the client
  class SourceAdapterServerTimeoutException < SourceAdapterException; end
  class SourceAdapterServerErrorException < SourceAdapterException; end

  class SourceAdapter
    attr_accessor :session,:default_sync
    
    def initialize(source=nil,credential=nil)
      @source = source.nil? ? self : source
    end

    def login; end
  
    def query; end
  
    # this base class sync method expects a hash of hashes, 'object' will be the key
    def sync; end
  
    def create(name_value_list); end

    def update(name_value_list); end

    def delete(name_value_list); end

    def logoff; end
  
    # only implement this if you want RhoSync to install a callback into your backend
    # def set_callback(notify_url)
    # end
  
    MSG_NO_OBJECTS = "No objects returned from query"
    MSG_NIL_RESULT_ATTRIB = "You might have expected a synchronization but the @result attribute was 'nil'"
  
    #################################################
    private 
    def result_empty?
      Logger.info MSG_NO_OBJECTS if @result.empty? 
      @result.empty?
    end

    def result_nil?
      Logger.error MSG_NIL_RESULT_ATTRIB if @result.nil?
      @result.nil?
    end

  end
end