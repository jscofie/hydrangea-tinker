require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe FileAssetsController do

  before do
    session[:user]='bob'
  end

  ## Plugin Tests
  it "should use FileAssetsController" do
    controller.should be_an_instance_of(FileAssetsController)
  end
  it "should be restful" do
    route_for(:controller=>'file_assets', :action=>'index').should == '/file_assets'
    route_for(:controller=>'file_assets', :action=>'show', :id=>"3").should == '/file_assets/3'
    route_for(:controller=>'file_assets', :action=>'destroy', :id=>"3").should  == { :method => 'delete', :path => '/file_assets/3' }
    route_for(:controller=>'file_assets', :action=>'update', :id=>"3").should == { :method => 'put', :path => '/file_assets/3' }
    route_for(:controller=>'file_assets', :action=>'edit', :id=>"3").should == '/file_assets/3/edit'
    route_for(:controller=>'file_assets', :action=>'new').should == '/file_assets/new'
    route_for(:controller=>'file_assets', :action=>'create').should == { :method => 'post', :path => '/file_assets' }
    
    params_from(:get, '/file_assets').should == {:controller=>'file_assets', :action=>'index'}
    params_from(:get, '/file_assets/3').should == {:controller=>'file_assets', :action=>'show', :id=>'3'}
    params_from(:delete, '/file_assets/3').should == {:controller=>'file_assets', :action=>'destroy', :id=>'3'}
    params_from(:put, '/file_assets/3').should == {:controller=>'file_assets', :action=>'update', :id=>'3'}
    params_from(:get, '/file_assets/3/edit').should == {:controller=>'file_assets', :action=>'edit', :id=>'3'}
    params_from(:get, '/file_assets/new').should == {:controller=>'file_assets', :action=>'new'}
    params_from(:post, '/file_assets').should == {:controller=>'file_assets', :action=>'create'}
  end
  
  describe "index" do
    
    it "should find all file assets in the repo if no container_id is provided" do
      #FileAsset.expects(:find_by_solr).with(:all, {}).returns("solr result")
      # Solr::Connection.any_instance.expects(:query).with('conforms_to_field:info\:fedora/afmodel\:FileAsset', {}).returns("solr result")
      Solr::Connection.any_instance.expects(:query).with('active_fedora_model_s:FileAsset', {}).returns("solr result")

      ActiveFedora::Base.expects(:new).never
      xhr :get, :index
      assigns[:solr_result].should == "solr result"
    end
    it "should find all file assets belonging to a given container object if container_id or container_id is provided" do
      mock_container = mock("container")
      mock_container.expects(:collection_members).with(:response_format => :solr).returns("solr result")
      ActiveFedora::Base.expects(:load_instance).with("_PID_").returns(mock_container)
      xhr :get, :index, :container_id=>"_PID_"
      assigns[:solr_result].should == "solr result"
      assigns[:container].should == mock_container
    end
    
    it "should find all file assets belonging to a given container object if container_id or container_id is provided" do
      pending
      # this was testing a hacked version
      mock_solr_hash = {"has_collection_member_field"=>["info:fedora/foo:id"]}
      mock_container = mock("container")
      mock_container.expects(:collection_members).with(:response_format=>:solr).returns("solr result")
      ActiveFedora::Base.expects(:load_instance).with("_PID_").returns(mock_container)
      #ActiveFedora::Base.expects(:find_by_solr).returns(mock("solr result", :hits => [mock_solr_hash]))
      #Solr::Connection.any_instance.expects(:query).with('id:foo\:id').returns("solr result")
      xhr :get, :index, :container_id=>"_PID_"
      assigns[:solr_result].should == "solr result"
      assigns[:container].should == mock_container
    end
  end

  describe "index" do
    before(:each) do
      Fedora::Repository.stubs(:instance).returns(stub_everything)
    end

    it "should be refined further!"
    
  end
  describe "new" do
    it "should return the file uploader view"
    it "should set :container_id to value of :container_id if available" do
      xhr :get, :new, :container_id=>"_PID_"
      params[:container_id].should == "_PID_"
    end
  end
  
  describe "create" do
    it "should init solr, create a FileAsset object, add the uploaded file to its datastreams, set the filename as its title, label, and the datastream label, and save the FileAsset" do
      ActiveFedora::SolrService.stubs(:register)
      mock_file = mock("File")
      filename = "Foo File"
      mock_fa = mock("FileAsset", :save)
      FileAsset.expects(:new).returns(mock_fa)
      mock_fa.expects(:add_file_datastream).with(mock_file, :label=>filename)
      mock_fa.expects(:label=).with(filename)
      xhr :post, :create, :Filedata=>mock_file, :Filename=>filename
    end
    it "if container_id is provided, should initialize a Base stub of the container, add the file asset to its relationships, and save both objects" do
      mock_file = mock("File")
      filename = "Foo File"
      mock_fa = mock("FileAsset", :save)
      FileAsset.expects(:new).returns(mock_fa)
      mock_fa.expects(:add_file_datastream).with(mock_file, :label=>filename)
      mock_fa.expects(:label=).with(filename)
      
      mock_container = mock("container")
      mock_container.expects(:file_objects_append).with(mock_fa) 
      mock_container.expects(:save)
      #mock_container.expects(:rels_ext).returns(mock("rels-ext", :save))
      ActiveFedora::Base.expects(:load_instance).with("_PID_").returns(mock_container)
      xhr :post, :create, :Filedata=>mock_file, :Filename=>filename, :container_id=>"_PID_"
    end
    
    it "should attempt to guess at type and set model accordingly" do
      FileAsset.expects(:new).never
      AudioAsset.expects(:new).times(3).returns(stub_everything)

      post :create, :Filename=>"meow.mp3", :Filedata=>"boo"
      post :create, :Filename=>"meow.wav", :Filedata=>"boo"
      post :create, :Filename=>"meow.aiff", :Filedata=>"boo"
      
      VideoAsset.expects(:new).times(2).returns(stub_everything)
      
      post :create, :Filename=>"meow.mov", :Filedata=>"boo"
      post :create, :Filename=>"meow.flv", :Filedata=>"boo"
      
      ImageAsset.expects(:new).times(4).returns(stub_everything)
      
      post :create, :Filename=>"meow.jpg", :Filedata=>"boo"
      post :create, :Filename=>"meow.jpeg", :Filedata=>"boo"
      post :create, :Filename=>"meow.png", :Filedata=>"boo"
      post :create, :Filename=>"meow.gif", :Filedata=>"boo"

    end    
  end
  describe "integration tests - " do
    before(:all) do
      Fedora::Repository.register(ActiveFedora.fedora_config[:url])
      ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
      @test_container = ActiveFedora::Base.new
      @test_container.add_relationship(:is_member_of, "foo:1")
      @test_container.add_relationship(:has_collection_member, "foo:2")
      @test_container.save
    end

    after(:all) do
     @test_container.delete
    end

    describe "index" do
      it "should retrieve the container object and its collection members" do
        #xhr :get, :index, :container_id=>@test_container.pid
        get :index, {:container_id=>@test_container.pid}
        params[:container_id].should_not be_nil
        assigns(:solr_result).should_not be_nil
        #puts assigns(:solr_result).inspect
        assigns(:container).collection_members(:response_format=>:id_array).should include("foo:2")
      end
    end
    
    describe "create" do
      it "should retain previously existing relationships in container object" do
        mock_file = mock("File")
        filename = "Foo File"
        mock_fa = mock("FileAsset", :pid=>"test:pid")
        mock_fa.stub_everything
        FileAsset.expects(:new).returns(mock_fa)
        post :create, {:Filedata=>mock_file, :Filename=>filename, :container_id=>@test_container.pid}
        assigns(:container).collection_members(:response_format=>:id_array).should include("foo:2")
      end
    end
  end
end