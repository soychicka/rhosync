# == Schema Information
# Schema version: 20090921184016
#
# Table name: client_maps
#
#  client_id       :string(36)    
#  object_value_id :integer(4)    
#  db_operation    :string(255)   
#  token           :string(255)   
#  dirty           :integer(1)    default(0)
#  ack_token       :integer(1)    default(0)
#

class ClientMap < ActiveRecord::Base
  belongs_to :client
  belongs_to :object_value
  
  # BEGIN client-sync methods
  
  # remove acknowledged token for client
  def self.mark_objs_by_ack_token(ack_token)
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute "update client_maps set ack_token=1 where token='#{ack_token}'"
      ActiveRecord::Base.connection.execute "delete from client_maps where token='#{ack_token}'
                                             and db_operation='delete'"
      ActiveRecord::Base.connection.execute "delete from client_temp_objects where token='#{ack_token}'"                                       
    end
  end

  # get insert objects based on token status
  def self.get_insert_objs_by_token_status(client_id,resend_token)
    objs_to_return = ObjectValue.find_by_sql "select * from object_values ov where id in
                                              (select object_value_id from client_maps as cm
                                                where cm.ack_token = 0
                                                and cm.db_operation != 'delete'
                                                and cm.client_id = '#{client_id}'
                                                and cm.token = #{resend_token})"
    return objs_to_return.collect! {|x| x.db_operation = 'insert'; x}
  end
  
  # get delete objects based on token status
  def self.get_delete_objs_by_token_status(client_id,resend_token)
    objs_to_return = []
    objs_to_delete = ClientMap.find_by_sql "select * from client_maps where ack_token = 0 and db_operation = 'delete' and client_id='#{client_id}' and token='#{resend_token}'"
    objs_to_delete.each do |map|
      objs_to_return << new_delete_obj(map.object_value_id)
    end
    objs_to_return
  end
  
  # look for changes in the current object_values list, return only records
  # for the current user if required
  def self.get_delete_objs_for_client(token,page_size,client_id,source_id)
    objs_to_return = []
    ActiveRecord::Base.transaction do
       if ActiveRecord::Base.connection.adapter_name.downcase == "oracle"
        objs_to_delete = ClientMap.find_by_sql "select * from client_maps cm left join object_values ov on
                                                cm.object_value_id = ov.id
                                                where cm.client_id='#{client_id}' and ov.id is NULL and ov.source_id=#{source_id} 
                                                and cm.dirty=0 and ROWNUM <= #{page_size} order by ov.object"
      elsif ActiveRecord::Base.connection.adapter_name.downcase == "sqlserver"
	      
        objs_to_delete = ClientMap.find_by_sql "select top #{page_size} * from client_maps cm left join object_values ov on
                                                cm.object_value_id = ov.id
                                                where cm.client_id='#{client_id}' and ov.id is NULL and ov.source_id=#{source_id} 
                                                and cm.dirty=0 order by ov.object"
      else	      
        objs_to_delete = ClientMap.find_by_sql "select * from client_maps cm left join object_values ov on
                                                cm.object_value_id = ov.id
                                                where cm.client_id='#{client_id}' and ov.id is NULL and ov.source_id=#{source_id} 
                                                and cm.dirty=0 order by ov.object limit #{page_size}"
      end
      objs_to_delete.each do |map|
        objs_to_return << new_delete_obj(map.object_value_id)
        # update this client_map record with a dirty flag and the token, 
        # so we don't send it more than once
        ActiveRecord::Base.connection.execute "update client_maps set db_operation='delete',token='#{token}',dirty=1,ack_token=0
                                               where object_value_id='#{map.object_value_id}'
                                               and client_id='#{map.client_id}'"
      end
    end
    objs_to_return
  end
  
  def self.process_create_objs_for_client(client_id,source_id,token)
    conditions = "client_id = '#{client_id}' and token is NULL and source_id = #{source_id}"
    temp_objects = ClientTempObject.find( :all, :conditions => conditions )

    temp_objects.map do |tmp_object|
      tmp_object.update_attribute(:token, token)
      tmp_object.save
    end
  end
  
  # Add insert objects to client_maps based on 
  # join query w/ object_values
  def self.insert_new_client_maps(insert_query)
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute "insert into client_maps (client_id,object_value_id,db_operation,token) #{insert_query}"                                      
    end
  end
  
  # generates an object_value for the client
  # to delete
  def self.new_delete_obj(obj_id)
    temp_obj = ObjectValue.new
    temp_obj.object = nil
    temp_obj.db_operation = "delete"
    temp_obj.created_at = temp_obj.updated_at = Time.now.to_s
    temp_obj.attrib = nil
    temp_obj.value = '-'
    temp_obj.update_type = 'delete'
    temp_obj.id = obj_id
    temp_obj.source_id = 0
    temp_obj
  end
end
