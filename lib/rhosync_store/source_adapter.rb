module RhosyncStore
  class SourceAdapterException < RuntimeError; end

  # raise this to cause client to be logged out during a sync
  class SourceAdapterLoginException < SourceAdapterException; end

  # raise these to trigger rhosync sending an error to the client
  class SourceAdapterServerTimeoutException < SourceAdapterException; end
  class SourceAdapterServerErrorException < SourceAdapterException; end

  class SourceAdapter
    attr_accessor :session
    
    def initialize(source,credential=nil)
      @source = source
    end
    
    # Returns an instance of a SourceAdapter by source name
    def self.create(source,credential=nil)
      adapter=nil
      if source
        begin
          Logger.info "Creating class for #{source.name}"
          require underscore(source.name)
          adapter=(Object.const_get(source.name)).new(source,credential) 
        rescue Exception=>e
          Logger.error "Failure to create adapter from class #{source.name}: #{e.inspect.to_s}"
          raise e
        end
      end
      adapter
    end

    def login; end
  
    def query; end
  
    # this base class sync method expects a hash of hashes, 'object' will be the key
    def sync
      return if result_nil? or result_empty?
      puts "inside source_adapter sync"
      @source.app.store.put_data(@source.document,@result)
    end
  
    def create(name_value_list); end

    def update(name_value_list); end

    def delete(name_value_list); end

    def logoff; end
  
    # only implement this if you want RhoSync to install a callback into your backend
    # def set_callback(notify_url)
    # end
  
    MSG_NO_OBJECTS = "No objects returned from query"
    MSG_NIL_RESULT_ATTRIB = "You might have expected a synchronization but the @result attribute was 'nil'"
    
    protected
    def current_user
      @source.user
    end
  
    #################################################
    private 
    def result_empty? #:nodoc:
      Logger.info MSG_NO_OBJECTS if @result.empty? 
      @result.empty?
    end

    def result_nil? #:nodoc:
      Logger.error MSG_NIL_RESULT_ATTRIB if @result.nil?
      @result.nil?
    end

  end
end