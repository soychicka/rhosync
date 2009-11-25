module RhosyncStore
  class Document
    attr_accessor :doctype,:app,:user,:source
    
    def initialize(doctype,app,user,source)
      @doctype,@app,@user,@source = doctype,app,user,source
    end
    
    def get_deleted_page_doc
      Document.new("#{@doctype}-deleted-page",@app,@user,@source)
    end
    
    def get_page_doc
      Document.new("#{@doctype}-page",@app,@user,@source)
    end
    
    def get_deleted_doc
      Document.new("#{@doctype}-deleted",@app,@user,@source)
    end
    
    def get_updated_doc
      Document.new("#{@doctype}-updated",@app,@user,@source)
    end
    
    def get_created_doc
      Document.new("#{@doctype}-created",@app,@user,@source)
    end
    
    def get_created_errors_doc
      Document.new("#{@doctype}-created-errors",@app,@user,@source)
    end
    
    def get_key
      "#{@doctype}:#{@app.to_s}:#{@user.to_s}:#{@source}"
    end
  end
end