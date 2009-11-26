module RhosyncStore
  class SourceSync

    attr_reader :adapter,:app,:user,:source
    
    def initialize(app,user,source)
      @app,@user,@source = app,user,source
      raise InvalidArgumentError.new('Invalid app') if app.nil?
      raise InvalidArgumentError.new('Invalid user') if user.nil?
      raise InvalidArgumentError.new('Invalid source') if source.nil?
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
    def read
      begin
        @adapter.query
        @adapter.sync
      rescue Exception => e
        Logger.error "SourceAdapter raised query exception: #{e}"
        # TODO: Notify client about the error
      end
      true
    end
    
    def process
      return if _auth_op('login') == false
      
      self.create
      self.update
      self.delete
      self.read
        
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
      modified_doc = _op_doc(operation)
      modified = @app.store.get_data(modified_doc)
      modified.each do |key,value|
        begin
          modified.delete(key)
          link = @adapter.send operation, value
          if operation == 'create' and link and link.is_a?(String)
            object_links[key] = { 'l' => link }
          end
        rescue Exception => e
          Logger.error "SourceAdapter raised #{operation} exception: #{e}"
          errors[key] = value
          break
        end
      end
      @app.store.put_data(_op_doc(operation,'_errors'),errors)
      @app.store.put_data(_op_doc(operation),modified)
      @app.store.put_data(_op_doc(operation,'_links'),object_links) if object_links.length > 0
      true
    end
    
    def _op_doc(operation,suffix='')
      @source.document.send "get_#{operation}d#{suffix}_doc"
    end
  end
end
