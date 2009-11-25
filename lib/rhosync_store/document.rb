module RhosyncStore
  class Document
    attr_accessor :doctype,:app,:user,:client,:source
    
    def initialize(doctype,app,user,client,source)
      @doctype,@app,@user,@client,@source = doctype,app,user,client,source
    end
    
    def get_deleted_page_doc
      _get_doc("deleted-page")
    end
    
    def get_page_doc
      _get_doc("page")
    end
    
    def get_deleted_doc
      _get_doc("deleted")
    end
    
    def get_deleted_errors_doc
      _get_doc("deleted-errors")
    end
    
    def get_updated_doc
      _get_doc("updated")
    end
    
    def get_updated_errors_doc
      _get_doc("updated-errors")
    end
    
    def get_created_doc
      _get_doc("created")
    end
    
    def get_created_errors_doc
      _get_doc("created-errors")
    end
    
    def get_created_links_doc
      _get_doc("created-links")
    end
    
    def get_key
      "#{@doctype}:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
    end
    
    private
    def _get_doc(suffix)
      Document.new("#{@doctype}-#{suffix}",@app,@user,@client,@source)
    end
  end
end