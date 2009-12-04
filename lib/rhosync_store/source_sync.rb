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
        # run query,sync
        params ? @adapter.query(params) : @adapter.query
        @adapter.sync
        # query,sync succeeded, remove errors
        @source.app.store.flash_data(@source.document.get_source_errors_dockey)
      rescue Exception => e
        # store sync,query exceptions to be sent to all clients for this source/user
        Logger.error "SourceAdapter raised read exception: #{e}"
        @source.app.store.put_data(@source.document.get_source_errors_dockey,
                                   {'read-error'=>{'message'=>e.message}},true)
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
        @source.app.store.flash_data(@source.document.get_source_errors_dockey) if operation == 'login'
      rescue Exception => e
        Logger.error "SourceAdapter raised #{operation} exception: #{e}"
        @source.app.store.put_data(@source.document.get_source_errors_dockey,
                                   {"#{operation}-error"=>{'message'=>e.message}},true)
        return false
      end
      true
    end
    
    def _process_cud(operation)
      errors = {}
      object_links = {}
      client_id = nil
      modified_doc = _op_dockey(@source.document,operation)
      modified = @source.app.store.get_data(modified_doc)
      # Process operation queue, one object at a time
      modified.each do |key,value|
        begin
          # Remove object from queue
          modified.delete(key)
          # Add id to object hash to forward to backend call
          value['id'] = key unless operation == 'create'
          # Extract meta-client_id so we can store it later
          client_id = value['rhomobile.rhoclient']
          value.delete('rhomobile.rhoclient')
          # Perform operation
          link = @adapter.send operation, value
          # Store object-id link for the client
          if operation == 'create' and link and link.is_a?(String)
            object_links[client_id] ||= {}
            object_links[client_id][key] = { 'l' => link }
          end
        rescue Exception => e
          Logger.error "SourceAdapter raised #{operation} exception: #{e}"
          errors[client_id] ||= {}
          errors[client_id][key] = value
          errors[client_id]["#{key}-error"] = {'message'=>e.message}
          break
        end
      end
      # Record errors
      doc = Document.new('cd',@source.app.id,@source.user.id,'',@source.name)
      errors.each do |client_id,errors|
        doc.client_id = client_id
        @source.app.store.put_data(_op_dockey(doc,operation,'_errors'),errors,true)
      end
      # Record links
      object_links.each do |client_id,links|
        doc.client_id = client_id
        @source.app.store.put_data(_op_dockey(doc,operation,'_links'),links,true)
      end
      # Record rest of queue (if something in the middle failed)
      @source.app.store.put_data(_op_dockey(@source.document,operation),modified)
      true
    end
    
    def _op_dockey(doc,operation,suffix='')
      doc.send "get_#{operation}#{suffix}_dockey"
    end
  end
end
