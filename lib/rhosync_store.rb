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
      data.each do |key,value|
        @db.sadd(object_id_set, key)
        value.each do |attrib,value|
          @db.sadd(object_set,_setelement(key,attrib,value))
        end
      end
      @db.set(_key_timestamp(doctype,source,user), (Time.now.to_f * 1000).to_i)
    end
    true
  end
  
  # Retrieves set for given doctype,source,user
  def get_data(doctype,source,user)
    res = {}
    if doctype and source and user
      @db.smembers(_setkey(doctype,source,user)).each do |element|
        key,attrib,value = _getelement(element)
        res[key] = {} unless res[key]
        res[key].merge!({attrib => value})
      end
      res
    end
  end
  
  # Retrieves diff data hash between two sets
  def get_diff_data(srcdoc,dstdoc,source,user)
    res = {}
    if srcdoc and dstdoc and source and user
      @db.sdiff(_setkey(dstdoc,source,user),_setkey(srcdoc,source,user)).each do |element|
        key,attrib,value = _getelement(element)
        res[key] = {} unless res[key]
        res[key].merge!({attrib => value})
      end
    end
    res
  end
  
  # Returns timestamp (integer) for given doctype,source,user
  def get_timestamp(doctype,source,user)
    ts = @db.get(_key_timestamp(doctype,source,user))
    ts ? ts.to_i : nil
  end
  
  # Compute difference between two sets
  def get_diff_ids(srcdoc,dstdoc,source,user)
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

  def _setelement(obj,attrib,value)
    "#{obj}:#{attrib}:#{Base64.encode64(value)}"
  end
  
  def _getelement(element)
    res = element.split(':')
    [res[0], res[1], Base64.decode64(res[2])]
  end
  
  def _key_timestamp(doctype,source,user)
    "#{_setkey(doctype,source,user)}:ts"
  end
  
  def _delete_keys(keymask)
    @db.keys(keymask).each do |key|
      @db.del(key)
    end
  end
end