module RhosyncStore
  class ClientSync
    attr_accessor :app,:user,:client,:source,:p_size,:source_sync,:client_store
    
    def initialize(app,user,client,source,p_size=500)
      @app,@user,@client,@source,@p_size = app,user,client,source,p_size
      @source_sync = SourceSync.new(@app,@user,@source)
      @client_store = ClientStore.new(@app.store,Document.new('cd',@app,@user,@client,@source))
    end
    
    def receive_cud(params)
      params.each do |key,value|
        _receive_cud(key,value)
      end
    end
    
    def process(params)
      #TODO handle ack insert and delete pages
      receive_cud(params)
      @source_sync.process
      send_cud
    end
    
    def send_cud
      res = {}
      res['insert'] = @client_store.put_page(@source.document,@p_size)
      res['delete'] = @client_store.put_deleted_page(@source.document,@p_size)
      @app.store.put_data(@client_store.clientdoc,res['insert'],true)
      @app.store.delete_data(@client_store.clientdoc,res['delete'])
      res
    end
    
    private
    def _receive_cud(operation,params)
      return if not ['create','update','delete'].include?(operation)
      doc = @source.document.send "get_#{operation}d_doc"
      @app.store.put_data(doc,params,true)
    end
  end
end