class SampleAdapter < SourceAdapter
  def initialize(source,credential)
    super(source,credential)
  end
 
  def login
    unless _is_empty?(current_user.login)
      true
    else
      raise SourceAdapterLoginException.new('Error logging in')
    end
  end
 
  def query
    product1 = {
      'name' => 'iPhone',
      'brand' => 'Apple',
      'price' => '199.99'
    }
    
    product2 = {
      'name' => 'G2',
      'brand' => 'Android',
      'price' => '99.99'
    }
    @result = {'1'=>product1,'2'=>product2}
  end
 
  def sync
    super
  end
 
  def create(name_value_list,blob=nil)
    _kill_fuze(name_value_list,"Error creating record") 
    if name_value_list and name_value_list['name'] == 'Droid'
      'obj4'
    else
      nil
    end
  end
 
  def update(name_value_list)
    _kill_fuze(name_value_list,"Error updating record") 
    nil
  end
 
  def delete(name_value_list)
    _kill_fuze(name_value_list,"Error deleting record") 
    nil
  end
 
  def logoff
    #TODO: write some code here if applicable
    # no need to do a raise here
  end
  
  private
  def _is_empty?(str)
    str.length <= 0
  end
  
  def _kill_fuze(name_value_list,msg)
    if name_value_list and name_value_list['name'] == 'Fuze'
      raise SourceAdapterServerErrorException.new(msg) 
    end
  end
end