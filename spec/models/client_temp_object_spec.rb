require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ClientTempObject do
  before(:each) do
    @valid_attributes = {
      :client_id => "value for client_id",
      :objectid => "value for objectid",
      :temp_objectid => "value for temp_objectid"
    }
  end

  it "should create a new instance given valid attributes" do
    ClientTempObject.create!(@valid_attributes)
  end
end
