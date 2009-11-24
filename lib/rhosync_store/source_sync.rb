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
    
    def process
      begin
        @adapter.login
        @adapter.query
        @adapter.sync
        @adapter.logoff
      rescue SourceAdapterException => sae
        Logger.error "SourceAdapter raised exception: #{sae}: #{sae.message}"
        raise sae
      end
      true
    end
  end
end
