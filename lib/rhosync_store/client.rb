module RhosyncStore
  class Client < Model
    field :device_type,:string
    field :user_id,:string
    
    def self.create(fields={})
      super(fields)
    end
  end
end