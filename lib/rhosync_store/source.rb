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
    field :user_id,:integer
    field :app_id,:integer
    
    attr_reader :document
    
    def self.create(fields={})
      fields[:name] ||= self.class.name
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:pollinterval] ||= 300
      fields[:priority] ||= 3
      super(fields)
    end
    
    def document
      @document.nil? ? @document = Document.new('md',self.name,self.user.id) : @document
    end
    
    def user
      User.with_key(@user_id)
    end
    
    def app
      App.with_key(@app_id)
    end
  end
end