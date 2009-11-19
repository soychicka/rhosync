module RhosyncStore
  class Document
    attr_accessor :doctype,:source,:user
    
    def initialize(doctype,source,user)
      @doctype,@source,@user = doctype,source,user
    end
    
    def get_deleted_doc
      Document.new("#{@doctype}-deleted-page",@source,@user)
    end
    
    def get_page_doc
      Document.new("#{@doctype}-page",@source,@user)
    end
    
    def get_key
      "#{@doctype}:#{@source}:#{@user.to_s}"
    end
  end
end