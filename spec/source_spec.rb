require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "Source" do
  it_should_behave_like "SourceAdapterHelper"
  
  it "should create source with @fields" do
    @s1 = Source.create(@fields)
    @s1.name.should == @fields[:name]
    @s1.url.should == @fields[:url]
    @s1.login.should == @fields[:login]
    @s1.app.name.should == @a_fields[:name]
    @s1.pollinterval.should == 300
    @s1.priority.should == 3
    @s1.callback_url.should be_nil

    @s2 = Source.with_key(@s1.id)
    @s2.name.should == @s1.name
    @s2.url.should == @s1.url
    @s2.login.should == @s1.login
    @s2.app.name.should == @s1.app.name
    @s2.pollinterval.should == 300
    @s2.priority.should == 3
    @s2.callback_url.should be_nil
  end
  
  it "should create source with user" do
    @s.user.login.should == @u_fields[:login]
  end
  
  it "should create source with app and document" do
    @s.app.name.should == @a_fields[:name]
    @s.document.get_key.should == "md:#{@s.app.id}:#{@u.id}:0:#{@fields[:name]}"
  end
end