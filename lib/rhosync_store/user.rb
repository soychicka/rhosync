module RhosyncStore
  class User < Model
    field :login,:string
    field :email,:string
    field :password,:string
    
    def self.create(fields={})
      super(fields)
    end
  end
end