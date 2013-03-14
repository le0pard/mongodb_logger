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
  end
end