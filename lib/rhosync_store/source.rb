module RhosyncStore
  class Source < Model
    field :name,:string
    field :url,:string
    field :login,:string
    field :password,:string
    field :pollinterval,:integer
    field :priority,:integer
    field :callback_url,:string
    field :user_id,:string
    field :app_id,:string
    attr_reader :document
    
    def self.create(fields={})
      fields[:name] ||= self.class.name
      fields[:id] = fields[:name]
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:pollinterval] ||= 300
      fields[:priority] ||= 3
      super(fields)
    end
    
    # Return the user associated with a source
    def user
      User.with_key(self.user_id)
    end
    
    # Return the app the source belongs to
    def app
      App.with_key(self.app_id)
    end
    
    def document
      @document.nil? ? @document = Document.new('md',self.app_id,self.user_id,'0',self.name) : @document
    end
  end
end