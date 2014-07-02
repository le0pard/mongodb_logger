require "spec_helper"

describe TestsController, type: :controller do
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
      expect(response.body).to eq("index")
    end

    it "log a single record" do
      expect(@collection.find.count).to eq(0)
      get :index
      expect(response).to be_success
      expect(@collection.find.count).to eq(1)
    end

    it "log a debug message" do
      get :index
      record = @collection.find.first
      expect(record).not_to be_nil
      expect(record["messages"]["info"]).not_to be_nil
      expect(record["messages"]["info"]).to be_a(Array)
      expect(record["messages"]["info"].size).to eq(1)
      expect(record["messages"]["info"].first).to eq(described_class::LOG_MESSAGE)
    end

    it "write request method" do
      get :index
      record = @collection.find.first
      expect(@collection.find.first['method']).to eq("GET")
    end

    it "add_metadata should work" do
      get :index
      record = @collection.find.first
      expect(record['user_id']).to eq(described_class::LOG_USER_ID)
      expect(record['application_name_again']).to eq(Rails.root.basename.to_s)
    end
  end

  describe "POST #create" do
    it "write request method" do
      post :create
      expect(@collection.find.first['method']).to eq("POST")
    end

    it "log find by params keys" do
      some_name = "name"
      post :create, activity: { name: some_name }
      expect(@collection.find({"params.activity.name" => some_name}).count).to eq(1)
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
      expect(@collection.find({"params.data.is_true" => true}).count).to eq(1)
      expect(@collection.find({"params.data.is_false" => false}).count).to eq(1)
      expect(@collection.find({"params.data.string" => "string"}).count).to eq(1)
      expect(@collection.find({"params.data.push_hash.yes" => "yes"}).count).to eq(1)
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
        expect(@collection.find({"params.data.new_string" => "string"}).count).to eq(1)
        # attachment
        expect(@collection.find({"params.data.some_key.file.content_type" => @content_type}).count).to eq(1)
        expect(@collection.find({"params.data.some_key.file.original_filename" => { "$exists" => true }}).count).to eq(1)
      end
    end

    it "not log hidden params" do
      post :create, order: { password: described_class::LOG_MESSAGE }
      expect(@collection.find({"params.order.password" => "[FILTERED]"}).count).to eq(1)
    end
  end

  describe "GET #new" do
    it "write log exceptions" do
      expect { get :new }.to raise_error RuntimeError, described_class::LOG_ERROR_MESSAGE
      expect(@collection.find({"messages.error" => /^#{described_class::LOG_ERROR_MESSAGE}/}).count).to eq(1)
      expect(@collection.find({"is_exception" => true}).count).to eq(1)
    end
  end

  describe "DELETE #destroy" do
    it "write request method" do
      id = 101
      delete :destroy, id: id
      expect(@collection.find.first['method']).to eq("DELETE")
      expect(@collection.find.first['params']['id'].to_i).to eq(id)
    end
  end
end