module Sync
  class Synchronizer

    attr_reader :sync_data, :source_id, :object_limit, :user_id
    
    def initialize(sync_data, source_id, object_limit = nil, user_id = nil)
      validate_init_args(sync_data, source_id, object_limit, user_id)
      @sync_data, @source_id, @user_id = sync_data, source_id, user_id
      @object_limit = (object_limit.blank? or object_limit.to_i == 0) ? nil : object_limit.to_i
    end
    
    def sync
      @parsed_objects = []
  
      @sync_data.each_pair do |object_key, object_attributes|
        break if object_limit_exceeded?
        
        object = ObjectParser.new(object_key, object_attributes, @source_id, @user_id)
        @parsed_objects << object.array_of_object_values
      end
      
      ObjectValue.import FIELDS, object_value_attributes_from_parsed_objects 
    end
    
    
    ################################
    private
    
    FIELDS = [:pending_id, :source_id, :object, :attrib, :value, :user_id, :attrib_type]
    
    def object_limit_exceeded?
      if @object_limit.nil?
        false
      else
        @parsed_objects.size >= @object_limit
      end
    end
    
    def object_value_attributes_from_parsed_objects
      sql_values = []
      @parsed_objects.flatten.each do |object_value_instance|
        sql_values << FIELDS.collect { |field_name| object_value_instance[field_name] }
      end
      sql_values
    end
    
    def validate_init_args(sync_data, source_id, object_limit, user_id)
      raise IllegalArgumentError.new("Invalid source_id '#{source_id}'") if source_id.nil?
      raise IllegalArgumentError.new("Invalid source_id '#{source_id}'") unless (source_id.is_a?(Fixnum) and (source_id > 0))
      raise IllegalArgumentError.new("Sync data was 'nil'") if sync_data.nil?
      raise IllegalArgumentError.new("Sync data is not a hash") unless sync_data.is_a? Hash
      raise IllegalArgumentError.new("Invalid object_limit '#{object_limit}'") unless nil_or_positive?(object_limit) 
      raise IllegalArgumentError.new("Invalid user_id '#{user_id}'") unless nil_or_fixnum_greater_than_zero?(user_id)
    end
    
    def nil_or_fixnum_greater_than_zero?(object)
      object.nil? or (object.is_a?(Fixnum) and (object > 0))
    end
    
    def nil_or_positive?(object)
      return (object.blank? or (object.to_i > -1) ) 
    end
  end
end
