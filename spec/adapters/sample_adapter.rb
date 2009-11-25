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
    if name_value_list and name_value_list['name'] == 'Fuze'
      raise SourceAdapterServerErrorException.new("Error creating record") 
    end
    @result
  end
 
  def update(name_value_list)
    #TODO: write some code here
    # be sure to have a hash key and value for "object"
    raise "Please provide some code to update a single object in the backend application using the hash values in name_value_list"
  end
 
  def delete(name_value_list)
    #TODO: write some code here if applicable
    # be sure to have a hash key and value for "object"
    # for now, we'll say that its OK to not have a delete operation
    # raise "Please provide some code to delete a single object in the backend application using the hash values in name_value_list"
  end
 
  def logoff
    #TODO: write some code here if applicable
    # no need to do a raise here
  end
  
  private
  def _is_empty?(str)
    str.length <= 0
  end
end