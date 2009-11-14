module RhosyncStore
  class Client

    def initialize(store,source,user,clientdoc)
      @store, @source, @user, @clientdoc = store, source, user, clientdoc       
    end
      
    #computes diffs between master doc and client doc, trims it to page size, stores page, and returns page as hash  
    def put_page(masterdoc,page_size)
      res = {}
      @store.get_diff_data(@clientdoc,masterdoc,@source,@user).each do |key,item|
        res[key] = item
        page_size -= 1
        break if page_size <= 0          
      end
      @store.put_data("#{@clientdoc}-page",@source, @user,res)
      res
    end
    
    #gets stored diffs page
    def get_page
      @store.get_data("#{@clientdoc}-page",@source, @user)
    end
      
  end
end
