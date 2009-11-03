require File.dirname(__FILE__) + "/../../../spec_helper"
require File.dirname(__FILE__) + "/sync_spec_helper"
require 'sync'

include Sync

describe "Sync::ClientMapper" do 
  before do 
    @valid_token = '123456789'
    @valid_client = Client.create(:client_id => 'foo-abc')
    @valid_app = App.create(:name => 'Testapp')
  end
  
  after do
    @valid_client.destroy
    @valid_app.destroy
  end
  
  it "should have token, client, and app" do
    cmapper = ClientMapper.new(@valid_client,@valid_token,@valid_app)
    cmapper.client == @valid_client
    cmapper.token.should == @valid_token
    cmapper.app.should == @valid_app
  end
end
