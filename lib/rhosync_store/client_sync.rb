module RhosyncStore
  class ClientSync
    attr_accessor :source,:client,:p_size,:source_sync,:clientdoc
    
    def initialize(source,client,p_size=500)
      @source,@client,@p_size = source,client,p_size
      @source_sync = SourceSync.new(@source)
      @clientdoc = Document.new('cd',@source.app.id,@source.user.id,@client.id,@source.name)
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
      res['insert'] = compute_page
      res['delete'] = compute_deleted_page
      @source.app.store.put_data(@clientdoc,res['insert'],true)
      @source.app.store.delete_data(@clientdoc,res['delete'])
      res
    end
    
    # Computes diffs between master doc and client doc, trims it to page size, 
    # stores page, and returns page as hash  
    def compute_page
      res = {}
      page_size = @p_size
      @source.app.store.get_diff_data(@clientdoc.get_key,@source.document.get_key).each do |key,item|
        res[key] = item
        page_size -= 1
        break if page_size <= 0          
      end
      @source.app.store.put_data(@clientdoc.get_page_dockey,res)
      res
    end
    
    # Computes deleted objects (down to individual attributes) 
    # in the client documet, trims it to page size, stores page, and returns page as hash      
    def compute_deleted_page
      res = {}
      deleted_page_key = @clientdoc.get_deleted_page_dockey
      page_size = @p_size
      @source.app.store.get_diff_data(@source.document.get_key,@clientdoc.get_key).each do |key,value|
        res[key] = value
        value.each do |attrib,val|
          @source.app.store.db.sadd(deleted_page_key,setelement(key,attrib,val))
        end
        page_size -= 1
        break if page_size <= 0          
      end
      res
    end
    
    # Resets the store for a given app,client
    def self.reset(app,user,client)
      doc = Document.new('cd',app.id,user.id,client.id,'*')
      app.store.get_keys(doc.get_key).each do |key|
        app.store.flash_data(key)
      end
    end
    
    private
    def _receive_cud(operation,params)
      return if not ['create','update','delete'].include?(operation)
      dockey = @source.document.send "get_#{operation}d_dockey"
      @source.app.store.put_data(dockey,params,true)
    end
  end
end