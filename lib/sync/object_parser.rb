module Sync
  class ObjectParser
    
    def initialize(object_key, object_attributes, source_id, user_id = nil)
      validate_init_args(object_key, object_attributes, source_id, user_id)
      
      @object_key, @object_attributes, @source_id, @user_id = 
        object_key, object_attributes, source_id, user_id 
      
      @object_values = []
      
      parse_object
    end
    
    def array_of_object_values
      @object_values
    end
    
    # Using :objects alias in the specs makes them easier to read as the context is clear.
    alias_method :objects, :array_of_object_values     
    
    #################################
    private 
    
    def parse_object
      prepare_common_attributes
      remove_overridden_source_id_from_object_attributes
      create_object_values
    end
    
    def prepare_common_attributes
      @common_attributes = {
        :source_id => @source_id,
        :object => @object_key,
        :user_id => @user_id }
    end
    
    def remove_overridden_source_id_from_object_attributes
      @overridden_source_id = @object_attributes.delete(:source_id)
    end
    
    def create_object_values
      @object_attributes.each_pair do |attribute_key, attribute_value|
        @object_values << parse_attributes(attribute_key, attribute_value)
      end
    end

    def parse_attributes(attribute_key, attribute_value)
      attribs = {
        :attrib => attribute_key, 
        :value => attribute_value.to_s,
      }
      
      attribs[:source_id] = @overridden_source_id if @overridden_source_id
      
      object_value = ObjectValue.new @common_attributes.merge(attribs)
      
      # This whole pending thing should be calculated in ObjectValue
      object_value.pending_id = 
        ObjectValue.hash_from_data(object_value.attrib, 
                                   object_value.object, 
                                   nil, 
                                   object_value.source_id, 
                                   object_value.user_id, 
                                   object_value.value )

      object_value
    end
    
    def validate_init_args(object_key, object_attributes, source_id, user_id)
      raise IllegalArgumentError.new("object_key was nil") if object_key.nil?
      raise IllegalArgumentError.new("object_attributes was nil") if object_attributes.nil? 
      raise IllegalArgumentError.new("object_attributes was not a Hash") unless object_attributes.is_a?(Hash)
      raise IllegalArgumentError.new("source_id was nil") if source_id.nil?
    end
    
  end
end
