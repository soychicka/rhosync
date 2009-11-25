module RhosyncStore
  class User < Model
    field :login,:string
    field :email,:string
    field :password,:string
    field :client_id,:integer
    
    def self.create(fields={})
      super(fields)
    end
    
    def client
      Client.with_key(self.client_id)
    end
  end
end