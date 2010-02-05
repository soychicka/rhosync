module Sync
  class ClientMapper
    attr_reader :client, :token, :app, :count
    
    def initialize(client,token,app)
      @client, @token, @app = client, token, app
    end
      
    # wrap object-values by object and source
    def wrap_object_values(ovlist)
      @count = 0
      list = {}
      return [] if @client.nil?
      temp_count = @client.client_temp_objects.count

      # process the ovlist (this will also include successful create objects)
      sources = @app.sources
      srchash = {}
      sources.each do |src|
        srchash[src.id] = src.name
      end

      ovlist.each do |ov|
        src_name = srchash[ov.source_id]
        src_name ||= 'RhoDeleteSource'
        obj_sym = ov.object.nil? ? nil : ov.object.to_sym
        obj_sym ||= :rho_del_obj
        old_obj = nil
        av_hash = { :i => ov.id, :d => ov.db_operation, :a => ov.attrib, :v => ov.value }

        if temp_count > 0
          # find the temp_obj that corresponds to the successful create
          tmp_obj = @client.client_temp_objects.find(:first, :conditions => {:objectid => ov.object, :error => nil})
        end
        old_objid = tmp_obj.temp_objectid if tmp_obj
        if list[src_name]
          if list[src_name][obj_sym]
            list[src_name][obj_sym][:av] << av_hash
            @count +=1
          else
            list[src_name][obj_sym] = { :oo => old_objid, :av => [av_hash] }
            @count +=1
          end
        else
          list[src_name] = { obj_sym => { :oo => old_objid, :av => [av_hash] } }
          @count +=1
        end
      end
      error_objs = ClientTempObject.find(:all, :conditions => "client_id = '#{@client.client_id}' and error is not NULL")

      error_objs.each do |err_obj|
        src_name = err_obj.source.nil? ? nil : err_obj.source.name
        if list[src_name]
          list[src_name][err_obj.temp_objectid.to_sym] = { :oo => err_obj.temp_objectid, :e => err_obj.error }
          @count +=1
        else
          list[src_name] = { err_obj.temp_objectid.to_sym => { :oo => err_obj.temp_objectid, :e => err_obj.error } }
          @count +=1
        end

        # make sure to set token, this may be the only object in the list
        @token = err_obj.token unless @token
      end
      list
    end

    # creates an object_value list for a given client
    # based on that client's client_map records
    # and the current state of the object_values table
    # since we do a delete_all in rhosync refresh,
    # only delete and insert are required
    def self.process_objects_for_client(current_user,source,client,token,ack_token,resend_token,p_size=nil,first_request=false,by_source=nil)

      # default page size of 10000
      page_size = p_size.nil? ? 10000 : p_size.to_i
      last_sync_time = Time.now
      objs_to_return = []
      by_source_condition = "and ov.source_id=#{source.id}" if by_source
      user_condition = "= #{current_user.id}" if current_user and current_user.id
      user_condition ||= "is NULL"

      # Setup the query conditions
      object_value_insert_query = "from object_values ov where ov.update_type='query' #{by_source_condition} and ov.user_id #{user_condition}
          and not exists (select object_value_id from client_maps where ov.id=object_value_id and client_id='#{client.id}') order by ov.object,ov.id limit #{page_size}"

      object_value_query = "select * from object_values ov inner join client_maps on ov.id = client_maps.object_value_id where token = '#{token}' order by ov.object,ov.id"

      # setup fields to insert in client_maps table
      object_insert_query = "select '#{client.id}',id,'insert','#{token}' #{object_value_insert_query}"

      # if we're resending the token, quickly return the results (inserts + deletes)
      if resend_token
        Rails.logger.debug "Resending token, resend_token: #{resend_token.inspect}"
        objs_to_return = ClientMap.get_delete_objs_by_token_status(client.id,resend_token)
        client.update_attributes({:updated_at => last_sync_time, :last_sync_token => resend_token})
        objs_to_return.concat( ClientMap.get_insert_objs_by_token_status(client.id,resend_token) )
      else
        Rails.logger.debug "ack_token: #{ack_token.inspect}, using new token: #{token.inspect}"

        # mark acknowledged token so we don't send it again
        ClientMap.mark_objs_by_ack_token(ack_token) if ack_token and ack_token.length > 0

        # find delete records
        objs_to_return.concat( ClientMap.get_delete_objs_for_client(token,page_size,client.id,source.id) )

        # process temp objects for this client
        ClientMap.process_create_objs_for_client(client.id,source.id,token)

        # find + save insert records
        ClientMap.insert_new_client_maps(object_insert_query)
        objs_to_insert = ObjectValue.find_by_sql object_value_query
        objs_to_insert.collect! {|x| x.db_operation = 'insert'; x}

        # Update the last updated time for this client
        # to track the last sync time
        client.update_attribute(:updated_at, last_sync_time)
        objs_to_return.concat(objs_to_insert)

        if token and objs_to_return.length > 0
          client.update_attribute(:last_sync_token, token)
        else
          client.update_attribute(:last_sync_token, nil)
        end
      end
      objs_to_return
    end
  end
end