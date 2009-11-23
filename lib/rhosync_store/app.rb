module RhosyncStore
  class App < Model
    field :name,:string
    
    attr_reader :store
    
    def self.create(fields={})
      super(fields)
    end
    
    def store
      @store.nil? ? @store = Store.new : @store
    end
  end
end