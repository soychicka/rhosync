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
    def put_data(dockey,data={},append=false)
      if dockey
        _delete_keys("#{dockey}*") unless append
        data.each do |key,value|
          value.each do |attrib,value|
            @db.sadd(dockey,setelement(key,attrib,value)) unless _is_reserved?(attrib,value)
          end
        end
      end
      true
    end
  
    # Retrieves set for given doctype,source,user
    def get_data(dockey)
      res = {}
      if dockey
        @db.smembers(dockey).each do |element|
          key,attrib,value = getelement(element)
          res[key] = {} unless res[key]
          res[key].merge!({attrib => value})
        end
        res
      end
    end
  
    # Retrieves diff data hash between two sets
    def get_diff_data(src_dockey,dst_dockey)
      res = {}
      if src_dockey and dst_dockey
        @db.sdiff(dst_dockey,src_dockey).each do |element|
          key,attrib,value = getelement(element)
          res[key] = {} unless res[key]
          res[key].merge!({attrib => value})
        end
      end
      res
    end
    
    # Deletes data from a given doctype,source,user
    def delete_data(dockey,data={})
      if dockey
        data.each do |key,value|
          value.each do |attrib,val|
            @db.srem(dockey,setelement(key,attrib,val))
          end
        end
      end
      true
    end
    
    private  
    def _delete_keys(keymask) #:nodoc:
      @db.keys(keymask).each do |key|
        @db.del(key)
      end
    end
    
    def _is_reserved?(attrib,value) #:nodoc:
      if RESERVED_ATTRIB_NAMES.include? attrib 
        Logger.error "Ignoring attrib-value pair: #{{attrib => value}.inspect}."
        true
      else
        false
      end
    end
  end
end  