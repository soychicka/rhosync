require 'rubygems'
require 'redis'
require 'base64'
require 'rhosync_store/document'
require 'rhosync_store/store'
require 'rhosync_store/client'

module RhosyncStore
  
  # Serializes oav to set element
  def setelement(obj,attrib,value)
    "#{obj}:#{attrib}:#{Base64.encode64(value.to_s)}"
  end
  
  # De-serializes oav from set element
  def getelement(element)
    res = element.split(':')
    [res[0], res[1], Base64.decode64(res[2])]
  end
  
  # TODO: replace with real logger
  class Logger
    def self.info(*args)
      puts args.join unless args.nil?
    end
    
    def self.error(*args)
      puts args.join unless args.nil?
    end
  end
end
