require "spec_helper"

describe TestsController do
  before :each do
    @mongodb_logger = Rails.logger
    @mongo_adapter = @mongodb_logger.mongo_adapter
    @mongo_adapter.reset_collection
    @collection = @mongo_adapter.collection
  end

  describe "GET #index" do
    it "responds successfully with an HTTP 200 status code" do
      get :index
      expect(response).to be_success
      expect(response.code.to_i).to eq(200)
    end

    it "renders the index text" do
      get :index
      response.should render_template(text: "index")
    end

    it "log a single record" do
      @collection.find.count.should == 0
      get :index
      expect(response).to be_success
      @collection.find.count.should == 1
    end

    it "log a debug message" do
      get :index
      record = @collection.find.first
      record.should_not be_nil
      record["messages"]["debug"].should_not be_nil
      record["messages"]["debug"].should be_a(Array)
      record["messages"]["debug"].size.should == 1
      record["messages"]["debug"].first.should == described_class::LOG_MESSAGE
    end

    it "write request method" do
      get :index
      record = @collection.find.first
      @collection.find.first['method'].should == "GET"
    end

    it "add_metadata should work" do
      get :index
      record = @collection.find.first
      record['user_id'].should == described_class::LOG_USER_ID
      record['application_name_again'].should == Rails.root.basename.to_s
    end
  end

  describe "POST #create" do
    it "write request method" do
      post :create
      @collection.find.first['method'].should == "POST"
    end

    it "log find by params keys" do
      some_name = "name"
      post :create, activity: { name: some_name }
      @collection.find({"params.activity.name" => some_name}).count.should == 1
    end

    it "search any values in params" do
      post :create, data: {
        int: 1,
        is_true: true,
        is_false: false,
        string: "string",
        push_hash: { yes: "yes" },
        float: 1.22
      }

      # such testing down on Rails 3.1.x, because in tests params convert Fixnum values into String
      # :(
      # assert_equal 1, @collection.find({"params.data.int" => 1}).count

      # data types
      @collection.find({"params.data.is_true" => true}).count.should == 1
      @collection.find({"params.data.is_false" => false}).count.should == 1
      @collection.find({"params.data.string" => "string"}).count.should == 1
      @collection.find({"params.data.push_hash.yes" => "yes"}).count.should == 1
    end

    context "search values in params" do
      before do
        @content_type = "text/html"
        @tempfile = Tempfile.new("file_#{rand(100)}.html")
        @tempfile.write("<html></html>")
        @tempfile.rewind
        @tempfile.close
      end
      after do
        @tempfile.unlink
      end

      it "with attachments" do
        uploaded_file = fixture_file_upload(@tempfile.path, @content_type, :binary)
        post :create, data: {
          some_key: { file: uploaded_file },
          new_string: "string"
        }
        # data types
        @collection.find({"params.data.new_string" => "string"}).count.should == 1
        # attachment
        @collection.find({"params.data.some_key.file.content_type" => @content_type}).count.should == 1
        @collection.find({"params.data.some_key.file.original_filename" => { "$exists" => true }}).count.should == 1
      end
    end

    it "not log hidden params" do
      post :create, order: { password: described_class::LOG_MESSAGE }
      @collection.find({"params.order.password" => "[FILTERED]"}).count.should == 1
    end
  end

  describe "GET #new" do
    it "write log exceptions" do
      expect { get :new }.to raise_error RuntimeError, described_class::LOG_ERROR_MESSAGE
      @collection.find({"messages.error" => /^#{described_class::LOG_ERROR_MESSAGE}/}).count.should == 1
      @collection.find({"is_exception" => true}).count.should == 1
    end
  end

  describe "DELETE #destroy" do
    it "write request method" do
      id = 101
      delete :destroy, id: id
      @collection.find.first['method'].should == "DELETE"
      @collection.find.first['params']['id'].to_i.should == id
    end
  end
end