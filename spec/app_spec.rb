require File.join(File.dirname(__FILE__),'spec_helper')

describe "App" do
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create app with fields" do
    @a.id.should == @a_fields[:name]
    @a1 = App.with_key(@a_fields[:name])
    @a1.id.should == @a.id
    @a1.name.should == @a_fields[:name]
  end
  
  it "should create app with store" do
    @a.name.should == @a_fields[:name]
    @a.store.db.class.should == Redis 
  end
end