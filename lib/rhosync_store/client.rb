module RhosyncStore
  class Client < Model
    field :device_type,:string
    
    def self.create(fields={})
      super(fields)
    end
  end
end