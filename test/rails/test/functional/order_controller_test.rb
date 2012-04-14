require 'test_helper'

class OrderControllerTest < ActionController::TestCase
  def setup
    @mongodb_logger = Rails.logger
    @mongodb_logger.reset_collection
    common_setup
  end

  test "should have log level set" do
    assert_equal ActiveSupport::BufferedLogger.const_get(Rails.configuration.log_level.to_s.upcase), Rails.logger.level
  end

  test "should log a single record" do
    get :index
    assert_response :success
    assert_equal 1, @collection.find({"controller" => "order","action"=> "index"}).count
  end

  test "should log a debug message" do
    get :index
    assert_equal OrderController::LOG_MESSAGE, @collection.find_one({}, :fields => ["messages"])["messages"]["debug"][0]
  end

  test "should log extra metadata" do
    get :index
    assert_equal Rails.root.basename.to_s, @collection.find_one({}, :fields => "application_name_again")["application_name_again"]
    assert_equal OrderController::LOG_USER_ID, @collection.find_one({}, :fields => "user_id")["user_id"]
  end
  
  test "should write GET request method" do
    get :index
    log = @collection.find_one()
    http_method = 'GET'
    assert_equal http_method, log['method']
  end
  
  test "should write POST request method" do
    post :create
    log = @collection.find_one()
    http_method = 'POST'
    assert_equal http_method, log['method']
  end

  test "should log exceptions" do
    assert_raise(RuntimeError, OrderController::LOG_MESSAGE) {get :new}
    assert_equal 1, @collection.find_one({"messages.error" => /^#{OrderController::LOG_MESSAGE}/})["messages"]["error"].count
    assert_equal 1, @collection.find_one({"is_exception" => true})["messages"]["error"].count
  end
  
  test "should log find by params keys" do
    some_name = "name"
    post :create, :activity => {:name =>  some_name}
    assert_equal 1, @collection.find({"params.activity.name" => some_name}).count
  end
  
  test "should search any values by params keys" do
    post :test_post, :data => {
      :int => 1,
      :is_true => true,
      :is_false => false,
      :string => "string",
      :push_hash => { :yes => "yes" },
      :float => 1.22
    }
    
    # such testing down on Rails 3.1.x, because in tests params convert Fixnum values into String
    # :(
    # assert_equal 1, @collection.find({"params.data.int" => 1}).count
    
    # data types
    assert_equal 1, @collection.find({"params.data.is_true" => true}).count
    assert_equal 1, @collection.find({"params.data.is_false" => false}).count
    assert_equal 1, @collection.find({"params.data.string" => "string"}).count
    assert_equal 1, @collection.find({"params.data.push_hash.yes" => "yes"}).count
  end
  
  test "should search any values by params keys with attachments" do
    filepath = "mltest_file.html"
    content_type = "text/html"
    tmpfile = File.open("#{ActionController::TestCase.fixture_path}#{filepath}", 'w') {|f| f.write("<html></html>") }
    
    uploaded_file = fixture_file_upload(filepath, content_type, :binary)
    post :test_post, :data => {
      :some_key => [
        {:file => uploaded_file}
      ],
      :int => 1,
      :is_true => true,
      :is_false => false,
      :string => "string",
      :push_hash => { :yes => "yes" },
      :float => 1.22
    }
    
    # data types
    assert_equal 1, @collection.find({"params.data.is_true" => true}).count
    assert_equal 1, @collection.find({"params.data.is_false" => false}).count
    assert_equal 1, @collection.find({"params.data.string" => "string"}).count
    assert_equal 1, @collection.find({"params.data.push_hash.yes" => "yes"}).count
    # attachment
    assert_equal 1, @collection.find({"params.data.some_key.file.content_type" => content_type}).count
    assert_equal 1, @collection.find({"params.data.some_key.file.original_filename" => filepath}).count
    
    File.delete(filepath) if File.exist?(filepath)
  end

  test "should not log passwords" do
    post :create, :order => {:password => OrderController::LOG_MESSAGE }
    assert_equal 1, @collection.find_one({"params.order.password" => "[FILTERED]"})["params"]["order"].count
  end

  test "should set the application name" do
    assert_equal 'mongo_foo', @mongodb_logger.instance_variable_get(:@application_name)
  end
end
