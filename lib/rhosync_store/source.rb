module RhosyncStore
  class Source < Model
    field :name,:string
    field :url,:string
    field :login,:string
    field :password,:string
    field :app,:string
    field :pollinterval,:integer
    field :priority,:integer
    field :callback_url,:string
    
    def self.create(fields={})
      fields[:name] ||= self.class.name
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:pollinterval] ||= 300
      fields[:priority] ||= 3
      super(fields)
    end
  end
end