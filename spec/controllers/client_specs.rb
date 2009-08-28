require File.dirname(__FILE__) + '/../spec_helper'

# Be sure to include AuthenticatedTestHelper in spec/spec_helper.rb instead
# Then, you can remove it from this and the units test.
include AuthenticatedTestHelper

describe SessionsController do

  before(:each) do
    User.destroy_all

    @app = mock_model(App, :autoregister => 1)
    @user = mock_model(User, :login => "newguy", :password => "password")
    App.stub!(:find).and_return(@app)
  end

  it "should autoregister user" do
    @app.should_receive(:authenticates?).and_return(true)
    @app.should_receive(:authenticate).and_return(@user)
    post :client_login, :source => "foo", :app_id => "bar", :login => "newguy", :password => "password"
    User.count.should == 1
  end

  it "should create a user" do
    post '/apps/5/sources/whatever/client_login?login=newguy&password=password'
    User.should_receive(:new)
  end
end
