module RhosyncStore
  class Document
    attr_accessor :doctype,:app_id,:user_id,:client_id,:source_name
    
    def initialize(doctype,app_id,user_id,client_id,source_name)
      @doctype,@app_id,@user_id,@client_id,@source_name = doctype,app_id,user_id,client_id,source_name
    end
    
    def get_deleted_page_dockey
      _get_doc("deleted-page")
    end
    
    def get_page_dockey
      _get_doc("page")
    end
    
    def get_deleted_dockey
      _get_doc("deleted")
    end
    
    def get_deleted_errors_dockey
      _get_doc("deleted-errors")
    end
    
    def get_updated_dockey
      _get_doc("updated")
    end
    
    def get_updated_errors_dockey
      _get_doc("updated-errors")
    end
    
    def get_created_dockey
      _get_doc("created")
    end
    
    def get_created_errors_dockey
      _get_doc("created-errors")
    end
    
    def get_created_links_dockey
      _get_doc("created-links")
    end

    def get_key
      "#{@doctype}:#{@app_id.to_s}:#{@user_id.to_s}:#{@client_id.to_s}:#{@source_name}"
    end
    
    private
    def _get_doc(suffix)
      "#{@doctype}-#{suffix}:#{@app_id.to_s}:#{@user_id.to_s}:#{@client_id.to_s}:#{@source_name}"
    end
  end
end