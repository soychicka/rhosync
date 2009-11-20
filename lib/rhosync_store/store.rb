module RhosyncStore
  class Store
    RESERVED_ATTRIB_NAMES = ["attrib_type", "id"] 
    attr_accessor :db

    def initialize
      @db = Redis.new
      raise "Error connecting to Redis store." unless @db and @db.is_a?(Redis)
    end
  
    # Adds set with given data, replaces existing set
    # if it exists or appends data to the existing set
    # if append flag set to true
    def put_data(document,data={},append=false)
      if document
        object_set = document.get_key
        _delete_keys("#{object_set}*") unless append
        data.each do |key,value|
          value.each do |attrib,value|
            @db.sadd(object_set,setelement(key,attrib,value)) unless _is_reserved?(attrib,value)
          end
        end
        @db.set(_key_timestamp(document), (Time.now.to_f * 1000).to_i)
      end
      true
    end
  
    # Retrieves set for given doctype,source,user
    def get_data(document)
      res = {}
      if document
        @db.smembers(document.get_key).each do |element|
          key,attrib,value = getelement(element)
          res[key] = {} unless res[key]
          res[key].merge!({attrib => value})
        end
        res
      end
    end
  
    # Retrieves diff data hash between two sets
    def get_diff_data(srcdoc,dstdoc)
      res = {}
      if srcdoc and dstdoc
        @db.sdiff(dstdoc.get_key,srcdoc.get_key).each do |element|
          key,attrib,value = getelement(element)
          res[key] = {} unless res[key]
          res[key].merge!({attrib => value})
        end
      end
      res
    end
  
    # Returns timestamp (integer) for given doctype,source,user
    def get_timestamp(doc)
      ts = @db.get(_key_timestamp(doc))
      ts ? ts.to_i : nil
    end
    
    # Deletes data from a given doctype,source,user
    def delete_data(document,data={})
      if document
        object_set = document.get_key
        data.each do |key,value|
          value.each do |attrib,val|
            @db.srem(object_set,setelement(key,attrib,val))
          end
        end
      end
      true
    end
    
    private  
    def _key_timestamp(doc)
      "#{doc.get_key}:ts"
    end
  
    def _delete_keys(keymask)
      @db.keys(keymask).each do |key|
        @db.del(key)
      end
    end
    
    def _is_reserved?(attrib,value)
      if RESERVED_ATTRIB_NAMES.include? attrib 
        Logger.error "Ignoring attrib-value pair: #{{attrib => value}.inspect}."
        true
      else
        false
      end
    end
  end
end  