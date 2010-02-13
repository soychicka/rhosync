require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SourcesController do
  fixtures :sources
  fixtures :users
  fixtures :apps

  before(:each) do
    login_as(:quentin)
  end

  def mock_source(stubs={})
    time = Time.now.to_s
    stubs = {:url=>'',
             :name=>'SugarAccounts',
             :login=>'',
             :adapter=>nil,
             :refreshtime=>time,
             "refreshtime=".to_sym=>time,
             :pollinterval=>300,
             :limit=>100,
             :app_id=>2,
             "app_id".to_sym=>2,
             :save=>true} unless stubs.size > 0
    @adapter = mock('SugarAccounts')
    add_stubs(@adapter, stubs)
    stubs['source_adapter'] = @adapter

    userstubs={:login=>'anton',:password=>'monkey'}
    anton=mock_model(User,userstubs)
    userstubs={:login=>'quentin',:password=>'monkey'}
    quentin=mock_model(User,userstubs)
    appstubs={
      :id=>2,
      :admin=>'quentin',
      :users=>[quentin,anton]
    }
    stubs[:app] = mock_model(App,appstubs)

    @mock_source = mock_model(Source, stubs)
  end

  def mock_records(stubs={})
    @mock_records = mock_model(ObjectValue, stubs)
  end

  describe "responding to GET show" do

    it "should expose the requested source as @source" do
      pending("Test needs to be brought up to date.")
      Source.should_receive(:find_by_permalink).with("37").and_return(mock_source)
      get :show, :id => "37"
      assigns[:source].should equal(mock_source)
    end

    describe "with mime type of xml" do
      it "should render the requested source as xml" do
        pending("Test needs to be brought up to date.")
        expected = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<nil-classes type=\"array\"/>\n"
        request.env["HTTP_ACCEPT"] = "application/xml"
        Source.should_receive(:find).with("37").and_return(mock_source)
        get :show, :id => "37", :format => "xml"
        response.body.should == expected
      end
    end
  end

  describe "responding to GET new" do

    it "should expose a new source as @source" do
      pending("Test needs to be brought up to date.")
      Source.should_receive(:new).and_return(mock_source)
      get :new
      assigns[:source].should equal(mock_source)
    end

  end

  describe "responding to GET edit" do

    it "should expose the requested source as @source" do
      pending("Test needs to be brought up to date.")
      Source.should_receive(:find).with(:first, {:conditions=>["id =:link or name =:link", {:link=>"37"}]}).and_return(mock_source)
      get :edit, :id => "37"
      assigns[:source].should equal(mock_source)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do

      it "should expose a newly created source as @source" do
        pending("Test needs to be brought up to date.")
        Source.should_receive(:new).with({'these' => 'params'}).and_return(mock_source(:save => true))
        post :create, :source => {:these => 'params'}
        assigns(:source).should equal(mock_source)
      end

      it "should redirect to the created source" do
        pending("Test needs to be brought up to date.")
        Source.stub!(:new).and_return(mock_source(:save => true))
        post :create, :source => {}
        response.should redirect_to(source_url(mock_source))
      end

    end

    describe "with invalid params" do

      it "should expose a newly created but unsaved source as @source" do
        pending("Test needs to be brought up to date.")
        Source.stub!(:new).with({'these' => 'params'}).and_return(mock_source(:save => false))
        post :create, :source => {:these => 'params'}
        assigns(:source).should equal(mock_source)
      end

      it "should re-render the 'new' template" do
        pending("Test needs to be brought up to date.")
        Source.stub!(:new).and_return(mock_source(:save => false))
        post :create, :source => {}
        response.should render_template('new')
      end

    end

  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested source" do
        pending("Test needs to be brought up to date.")
        Source.should_receive(:find).with("37").and_return(mock_source)
        mock_source.should_receive(:update_attributes).with({'these' => 'params','app_id'=>2})
        put :update, :id => "37", :source => {:these => 'params',:app_id=>2}
      end

      it "should expose the requested source as @source" do
        pending("Test needs to be brought up to date.")
        Source.stub!(:find).and_return(mock_source(:update_attributes => true, :save_to_yaml => true))
        put :update, :id => "1", :source => {:these => 'params',:app_id=>2}
        assigns(:source).should equal(mock_source)
      end

      it "should redirect to the source" do
        pending("Test needs to be brought up to date.")
        Source.stub!(:find).and_return(mock_source(:update_attributes => true, :save_to_yaml => true))
        put :update, :id => "1",:source => {:these => 'params',:app_id=>2}
        response.should redirect_to(app_sources_url(2))
      end

    end

    describe "with invalid params" do

      it "should update the requested source" do
        pending("Test needs to be brought up to date.")
        Source.should_receive(:find).with("37").and_return(mock_source)
        mock_source.should_receive(:update_attributes).with({'these' => 'params','app_id'=>2})
        put :update, :id => "37", :source => {:these => 'params',:app_id=>2}
      end

      it "should expose the source as @source" do
        pending("Test needs to be brought up to date.")
        Source.stub!(:find).and_return(mock_source(:update_attributes => false))
        put :update, :id => "1",:source => {:these => 'params',:app_id=>2}
        assigns(:source).should equal(mock_source)
      end

      it "should re-render the 'edit' template" do
        pending("Test needs to be brought up to date.")
        Source.stub!(:find).and_return(mock_source(:update_attributes => false))
        put :update, :id => "1",:source => {:these => 'params',:app_id=>2}
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested source" do
      pending("Test needs to be brought up to date.")
      Source.should_receive(:find).with("37").and_return(mock_source)
      mock_source.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "should redirect to the sources list" do
      pending("Test needs to be brought up to date.")
      Source.stub!(:find).and_return(mock_source(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(sources_url)
    end

  end

  describe "responding to createobjects, deleteobjects, updateobjects" do
    it "should createobjects" do
      Source.should_receive(:find).with(37).and_return(mock_source)
      get :createobjects,:id => "37", :attrvals => [{"object"=>"temp1","attrib"=>"name","value"=>"rhomobile"}]
      response.should be_redirect
    end

    it "should updateobjects" do
      Source.should_receive(:find).with(37).and_return(mock_source)
      get :updateobjects,:id => "37", :attrvals => [{"object"=>"1","attrib"=>"name","value"=>"rhomobile"}]
      response.should be_redirect
    end

    it "should deleteobjects" do
      Source.should_receive(:find).with(37).and_return(mock_source)
      get :deleteobjects, :id => "37", :attrvals => [{"object"=>"1"}]
      response.should be_redirect
    end

    it "should refresh" do
      pending("Test needs to be brought up to date.")
      Source.should_receive(:find).with(37).and_return(mock_source)
      get :show, :id => "37", :refresh => true
      response.should render_template('show')
    end

  end

  describe "responding to GET clientcreate" do

    it "should return the created client" do
      get :clientcreate, :format => 'json'
      response.body.should =~ /(^[^\r\n]+?)([A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}(?:@[^\s]*)?|@[^\s]*|\s*$)/
    end

  end
end
