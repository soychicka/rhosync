require File.join(File.dirname(__FILE__),'spec_helper')

describe "Client" do
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create client with fields" do
    @c.id.should == 1
    @c.device_type.should == @c_fields[:device_type]
  end
  
  it "should create client with user_id" do
    @c.id.should == 1
    @c.user_id.should == @c_fields[:user_id] 
  end
end