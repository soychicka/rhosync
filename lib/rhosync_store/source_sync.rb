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
    
    # Process created objects one at a time.
    # If create fails, store as an error.
    def create
      errors = {}
      @created = @app.store.get_data(@source.document.get_created_doc)
      @created.each do |key,value|
        begin
          @created.delete(key)
          @adapter.create(value)
        rescue Exception => e
          Logger.error "SourceAdapter raised create exception: #{e}"
          errors[key] = value
          break
        end
      end
      @app.store.put_data(@source.document.get_created_errors_doc,errors)
      @app.store.put_data(@source.document.get_created_doc,@created)
      true
    end
    
    def process
      begin
        @adapter.login
        @adapter.query
        @adapter.sync
        @adapter.logoff
      rescue SourceAdapterException => sae
        Logger.error "SourceAdapter raised exception: #{sae}"
        raise sae
      end
      true
    end
  end
end
