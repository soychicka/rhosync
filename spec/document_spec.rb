require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "Document" do
  before(:each) do
    @doctype = 'md'
    @source = 'TestSource'
    @user = 5
    @client = 12345
    @app = 2
    @d = Document.new(@doctype,@app,@user,@client,@source)
  end
  
  it "should get_key" do
    @d.get_key.should == "#{@doctype}:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_deleted_page_dockey" do
    @d.get_deleted_page_dockey.should == "#{@doctype}-deleted-page:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_page_dockey" do
    @d.get_page_dockey.should == "#{@doctype}-page:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_page_token_dockey" do
    @d.get_page_token_dockey.should == "#{@doctype}-page-token:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_updated_dockey" do
    @d.get_updated_dockey.should == "#{@doctype}-updated:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_deleted_dockey" do
    @d.get_deleted_dockey.should == "#{@doctype}-deleted:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_deleted_errors_dockey" do
    @d.get_deleted_errors_dockey.should == "#{@doctype}-deleted-errors:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_created_dockey" do
    @d.get_created_dockey.should == "#{@doctype}-created:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_created_errors_dockey" do
    @d.get_created_errors_dockey.should == "#{@doctype}-created-errors:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"
  end
  
  it "should get_created_links_dockey" do
    @d.get_created_links_dockey.should == "#{@doctype}-created-links:#{@app.to_s}:#{@user.to_s}:#{@client.to_s}:#{@source}"    
  end
end