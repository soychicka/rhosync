require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "Document" do
  before(:each) do
    @doctype = 'md'
    @source = 'TestSource'
    @user = 5
    @d = Document.new(@doctype,@source,@user)
  end
  
  it "should get_key" do
    @d.get_key.should == "#{@doctype}:#{@source}:#{@user.to_s}"
  end
  
  it "should get_deleted_doc" do
    @d.get_deleted_doc.get_key.should == "#{@doctype}-deleted-page:#{@source}:#{@user.to_s}"
  end
  
  it "should get_page_doc" do
    @d.get_page_doc.get_key.should == "#{@doctype}-page:#{@source}:#{@user.to_s}"
  end
end