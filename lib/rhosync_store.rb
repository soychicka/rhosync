require 'rubygems'
require 'redis'
require 'base64'

class RhosyncStore
  attr_accessor :db

  def initialize
    @db = Redis.new
    raise "Error connecting to Redis store." unless @db and @db.is_a?(Redis)
  end
  
  # Adds set with given data, replaces existing set
  # if it exists
  def put_data(doctype,source,user,data={})
    if doctype and source and user
      object_set = _setkey(doctype,source,user)
      object_id_set = "#{object_set}:ids"
      _delete_keys("#{object_set}*")
      now = Time.now.to_i
      data.each do |key,value|
        @db.sadd(object_id_set, key)
        value.each do |attrib,value|
          @db.sadd(object_set,_setelement(key,attrib,value,now))
        end
      end
    end
    true
  end
  
  # Retrieves set for given source,user
  def get_data(doctype,source,user,set=nil)
    res = {}
    if doctype and source and user
      @db.smembers(_setkey(doctype,source,user)).each do |element|
        key,attrib,value,timestamp = _getelement(element)
        res[key] = {} unless res[key]
        res[key].merge!({attrib => value})
      end
      res
    end
  end
  
  # Compute difference between two sets
  def get_deleted(srcdoc,dstdoc,source,user)
    res = []
    if srcdoc and dstdoc and source and user
      res = @db.sdiff(_setkey_ids(dstdoc,source,user),_setkey_ids(srcdoc,source,user))
    end
    res
  end
  
  private
  def _setkey(doctype,source,user)
    "#{doctype}:#{source}:#{user.to_s}"
  end
  
  def _setkey_ids(doctype,source,user)
    "#{_setkey(doctype,source,user)}:ids"
  end
  
  def _setelement(obj,attrib,value,timestamp)
    "#{obj}:#{attrib}:#{Base64.encode64(value)}:#{timestamp}"
  end
  
  def _getelement(element)
    res = element.split(':')
    [res[0], res[1], Base64.decode64(res[2]), res[3]]
  end
  
  def _delete_keys(keymask)
    @db.keys(keymask).each do |key|
      @db.del(key)
    end
  end
end