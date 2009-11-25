module RhosyncStore
  class Client
    def initialize(store,clientdoc)
      @store,@clientdoc = store,clientdoc       
    end
      
    # Computes diffs between master doc and client doc, trims it to page size, 
    # stores page, and returns page as hash  
    def put_page(masterdoc,page_size)
      res = {}
      @store.get_diff_data(@clientdoc,masterdoc).each do |key,item|
        res[key] = item
        page_size -= 1
        break if page_size <= 0          
      end
      @store.put_data(@clientdoc.get_page_doc,res)
      res
    end
    
    # Computes deleted objects (down to individual attributes) 
    # in the client documet, trims it to page size, stores page, and returns page as hash      
    def put_deleted_page(masterdoc,page_size)
      res = {}
      delkey = @clientdoc.get_deleted_page_doc.get_key
      @store.get_diff_data(masterdoc,@clientdoc).each do |key,value|
        res[key] = value
        value.each do |attrib,val|
          @store.db.sadd(delkey,setelement(key,attrib,val))
        end
        page_size -= 1
        break if page_size <= 0          
      end
      res
    end
      
    # Gets stored diffs page
    def get_page
      @store.get_data(@clientdoc.get_page_doc)
    end

    # Gets stored deleted page
    def get_deleted_page
      @store.get_data(@clientdoc.get_deleted_page_doc)
    end         
  end
end
