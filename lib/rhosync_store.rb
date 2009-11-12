require 'rubygems'
require 'redis'

class RhosyncStore
  attr_accessor :db

  def initialize
    @db = Redis.new
    raise "Error connecting to Redis store." unless @db and @db.is_a?(Redis)
  end
  
  # Adds set with given data, replaces existing set
  # if it exists
  def put_data(source,user,data={})
    if source and user
      key_prefix = _setkey_prefix(source,user)
      _delete_keys("#{key_prefix}:*")
      data.each do |key,value|
        value.each do |item|
          @db.sadd(_setkey(key_prefix,key),Marshal.dump(item))
        end
      end
    end
    true
  end
  
  # Retrieves set for given source,user
  def get_data(source,user,client_id=nil)
    res = {}
    if source and user
      @db.keys(_setkey_prefix_wild(source,user)).each do |key|
        skey = key.split(':')[2]
        res[skey] = {}
        @db.smembers(key).each do |member|
          arr = Marshal.load(member)
          res[skey].merge!(arr[0] => arr[1])
        end
      end
      res
    end
  end
  
  # Retrieves set for given source,user,client
  def get_client_data(source,user,client)
    res = {}
    if source and user and client_id
      @db.keys("#{client_id}:#{_setkey_prefix_wild(source,user)}").each do |key|
        skey = key.split(':')[3]
        res[skey] = {}
        @db.smembers(key).each do |member|
          
        end
      end
    end
  end
  
  private
  def _setkey_prefix(source,user)
    "#{source}:#{user.to_s}"
  end
  
  def _setkey_prefix_wild(source,user)
    "#{_setkey_prefix(source,user)}:*"
  end
  
  def _setkey(prefix,element)
    "#{prefix}:#{element.to_s}"
  end
  
  def _delete_keys(keymask)
    @db.keys(keymask).each do |key|
      @db.del(key)
    end
  end
end