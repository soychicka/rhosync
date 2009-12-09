class SampleAdapter < SourceAdapter
  ERROR = '0'
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
    raise SourceAdapterLoginException.new('Error logging in') if _is_empty?(current_user.login)
    true
  end
 
  def query(params=nil)
    @result = @source.app.store.get_data('test_db_storage')
    raise SourceAdapterServerErrorException.new(@result[ERROR]['message']) if @result[ERROR] and 
      @result[ERROR]['name'] == 'query error'
    @result.reject! {|key,value| value['name'] != params['name']} if params
    @result
  end
 
  def sync
    super
  end
 
  def create(name_value_list,blob=nil)
    raise SourceAdapterException.new("ID provided in name_value_list") if name_value_list['id']
    _raise_exception(name_value_list) 
    if name_value_list and name_value_list['link']
      'backend_id'
    end
  end
 
  def update(name_value_list)
    raise SourceAdapterException.new("No id provided in name_value_list") unless name_value_list['id']
    _raise_exception(name_value_list) 
  end
 
  def delete(name_value_list)
    raise SourceAdapterException.new("No id provided in name_value_list") unless name_value_list['id']
    _raise_exception(name_value_list)  
  end
 
  def logoff
    @result = @source.app.store.get_data('test_db_storage')
    raise SourceAdapterLogoffException.new(@result[ERROR]['message']) if @result[ERROR] and 
      @result[ERROR]['name'] == 'logoff error'
  end
  
  private
  def _is_empty?(str)
    str.length <= 0
  end
  
  def _raise_exception(name_value_list)
    if name_value_list and name_value_list['name'] == 'error' or name_value_list['id'] == 'error'
      raise SourceAdapterServerErrorException.new(name_value_list['message']) 
    end
  end
end