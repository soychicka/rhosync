module RhosyncStore
  class SourceSync
    attr_reader :adapter
    
    def initialize(source)
      @source = source
      raise InvalidArgumentError.new('Invalid source') if @source.nil?
      @adapter = SourceAdapter.create(@source)
    end
    
    # CUD Operations
    def create
      _process_cud('create')
    end
    
    def update
      _process_cud('update')
    end
    
    def delete
      _process_cud('delete')
    end
    
    # Read Operation
    def read(params=nil)
      begin
        params ? @adapter.query(params) : @adapter.query
        @adapter.sync
      rescue Exception => e
        Logger.error "SourceAdapter raised query exception: #{e}"
        # TODO: Notify client about the error
      end
      true
    end
    
    def process(params=nil)
      return if _auth_op('login') == false
      
      self.create
      self.update
      self.delete
      self.read(params)
        
      _auth_op('logoff')
    end
    
    private
    def _auth_op(operation)
      begin
        @adapter.send operation
      rescue Exception => e
        Logger.error "SourceAdapter raised #{operation} exception: #{e}"
        return false
      end
      true
    end
    
    def _process_cud(operation)
      errors = {}
      object_links = {}
      modified_doc = _op_dockey(operation)
      modified = @source.app.store.get_data(modified_doc)
      modified.each do |key,value|
        begin
          modified.delete(key)
          value['id'] = key unless operation == 'create'
          client_id = nil
          if operation == 'create'
            client_id = value['rhomobile.rhoclient']
            value.delete('rhomobile.rhoclient')
          end
          link = @adapter.send operation, value
          if operation == 'create' and link and link.is_a?(String)
            object_links[client_id] ||= {}
            object_links[client_id][key] = { 'l' => link }
          end
        rescue Exception => e
          Logger.error "SourceAdapter raised #{operation} exception: #{e}"
          errors[key] = value
          errors["#{key}-error"] = {'message'=>e.message}
          break
        end
      end
      @source.app.store.put_data(_op_dockey(operation,'_errors'),errors)
      @source.app.store.put_data(_op_dockey(operation),modified)
      if operation == 'create'
        doc = Document.new('cd',@source.app.id,@source.user.id,'',@source.name)
        object_links.each do |client_id,objects|
          doc.client_id = client_id
          @source.app.store.put_data(doc.get_created_links_dockey,objects,true)
        end
      end
      true
    end
    
    def _op_dockey(operation,suffix='')
      @source.document.send "get_#{operation}d#{suffix}_dockey"
    end
  end
end
