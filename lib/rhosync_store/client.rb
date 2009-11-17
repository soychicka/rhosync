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
    
    #computes deleted objects (down to individual attributes) 
    #in the client documet, trims it to page size, stores page, and returns page as hash      
    def put_deleted_page(masterdoc,page_size)
      res = {'D'=>{}}
      @store.get_diff_data(masterdoc,@clientdoc,@source,@user).each do |key,item|
        attributes = []
        item.each do |name,value|
          attributes << name
        end  
        res['D'][key] = attributes.join(",")
        page_size -= 1
        break if page_size <= 0          
      end
      @store.put_data("#{@clientdoc}-deleted-page",@source, @user,res)
      res
    end
      
    #gets stored diffs page
    def get_page
      @store.get_data("#{@clientdoc}-page",@source, @user)
    end

    #gets stored deleted page
    def get_deleted_page
      @store.get_data("#{@clientdoc}-deleted-page",@source, @user)
    end
              
  end
end
