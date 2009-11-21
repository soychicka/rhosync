module RhosyncStore
  class SourceSync

    attr_reader :store,:sync_data,:source,:user_id,:doc
    
    def initialize(store,source,user_id=nil)
      @store,@source_id,@user_id = store,source_id,user_id
      @doc = Document.new('md',@source,@user_id)
    end
    
    def process
      # setup credentials
      _init_adapter(@user_id,session)
      
      # run create,update,delete,query
      
      @store.put_data(@doc,@sync_data)
      
    end
  end
end
