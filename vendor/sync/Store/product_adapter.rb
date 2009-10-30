require 'product'

# This adapter shows how you can use an ActiveResource model (in this case 'product')
# as your rhodes object
class ProductAdapter < SourceAdapter
  def query(conditions=nil,limit=nil,offset=nil)
  	# unfortuantely activeresource doesnt suport conditions, limit and offset directly
    @result = Product.find(:all)
    if limit && offset
    	@result = @result[offset, offset+limit]
    end
    @result = @result ? Product.hashinate(@result) : nil
  end
  
  # ENABLE THIS IF YOU WANT TO TEST BACKGROUND SYNC AKA PAGED QUERY
  # implemented in terms of query
  def page(num)
    Rails.logger.debug "page %d num class is %s" % [num, num.class.to_s]
    @result = query(nil, 10, num.to_i * 10)
  end

  def create(name_value_list)
    attrvals = {}
    name_value_list.each { |nv| attrvals[nv["name"].to_sym] = nv["value"] }
    res = Product.create(attrvals)
    
    # returning id to trigger save in rhosync client_temp_objects table
    #res.id.to_s 
  end

  def update(name_value_list)
    obj_id = name_value_list.find { |item| item['name'] == 'id' }
    name_value_list.delete(obj_id)

    #  The name_value_list:
    #  [{"name"=>"name", "value"=>"iPhone"}]
    attrvals = {}
    name_value_list.each { |nv| attrvals[nv["name"]]=nv["value"]}

    # Should be something like:
    # {"name" => "iPhone"}
    product = Product.find(obj_id['value'])
    product.attributes = product.attributes.merge(attrvals)
    product.save
  end

  def delete(name_value_list)
    obj_id = name_value_list.find { |item| item['name'] == 'id' }
    product = Product.find(obj_id['value'])
    product.destroy if product
  end
end