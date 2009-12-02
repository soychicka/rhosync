class StorageAdapter < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
    true
  end
 
  def query
    @result = {}
  end
 
  def sync
    super
  end
 
  def create(name_value_list,blob=nil)
    @source.app.store.put_data('test_create_storage',{name_value_list['_id']=>name_value_list},true)
  end
 
  def update(name_value_list)
    @source.app.store.put_data('test_update_storage',{name_value_list['id']=>name_value_list},true)
  end
 
  def delete(name_value_list)
    @source.app.store.put_data('test_delete_storage',{name_value_list['id']=>name_value_list},true)
  end
 
  def logoff
    
  end
end