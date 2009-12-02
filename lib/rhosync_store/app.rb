module RhosyncStore
  class App < Model
    field :name, :string
    attr_reader :store
    
    def self.create(fields={})
      fields[:id] = fields[:name]
      super(fields)
    end
    
    # Returns the data-store for an App
    def store
      @store.nil? ? @store = Store.new : @store
    end
  end
end