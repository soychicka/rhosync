module RhosyncStore
  class SourceSync

    attr_reader :store,:sync_data,:source,:user_id,:doc
    
    def initialize(store,source,user_id=nil)
      @store,@source_id,@user_id = store,source_id,user_id
      @doc = Document.new('md',@source,@user_id)
    end
    
    def process
      _init_adapter(@user_id,session)
      
      @store.put_data(@doc,@sync_data)
      
    end
    
    def _init_adapter(credential,session)
      if @source
        begin
          Logger.info "Creating class for #{@source}"
          @source_adapter=(Object.const_get(@source)).new(self,credential) 
          @source_adapter.session = session if session
        rescue Exception=>e
          Logger.error "Failure to create adapter from class #{@source}: #{e.inspect.to_s}"
        end
      end
    end
  end
end
