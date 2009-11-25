require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "Document" do
  before(:each) do
    @doctype = 'md'
    @source = 'TestSource'
    @user = 5
    @app = 2
    @d = Document.new(@doctype,@app,@user,@source)
  end
  
  it "should get_key" do
    @d.get_key.should == "#{@doctype}:#{@app.to_s}:#{@user.to_s}:#{@source}"
  end
  
  it "should get_deleted_page_doc" do
    @d.get_deleted_page_doc.get_key.should == "#{@doctype}-deleted-page:#{@app.to_s}:#{@user.to_s}:#{@source}"
  end
  
  it "should get_page_doc" do
    @d.get_page_doc.get_key.should == "#{@doctype}-page:#{@app.to_s}:#{@user.to_s}:#{@source}"
  end
  
  it "should get_updated_doc" do
    @d.get_updated_doc.get_key.should == "#{@doctype}-updated:#{@app.to_s}:#{@user.to_s}:#{@source}"
  end
  
  it "should get_deleted_doc" do
    @d.get_deleted_doc.get_key.should == "#{@doctype}-deleted:#{@app.to_s}:#{@user.to_s}:#{@source}"
  end
  
  it "should get_created_doc" do
    @d.get_created_doc.get_key.should == "#{@doctype}-created:#{@app.to_s}:#{@user.to_s}:#{@source}"
  end
  
  it "should get_created_errors_doc" do
    @d.get_created_errors_doc.get_key.should == "#{@doctype}-created-errors:#{@app.to_s}:#{@user.to_s}:#{@source}"
  end
end