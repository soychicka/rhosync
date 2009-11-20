module RhosyncStore
  class User
    attr_accessor :uid
    
    def initialize(uid)
      @uid = uid
    end
  end
end