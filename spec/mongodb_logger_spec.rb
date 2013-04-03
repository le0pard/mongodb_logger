require 'spec_helper'

describe MongodbLogger::Logger do
  extend MongodbLogger::SpecMacros

  EXCEPTION_MSG = "Foo"

  before :all do
    create_logs_dir
  end

  context "in instantiation" do
    before do
      described_class.any_instance.stub(:internal_initialize).and_return(nil)
      described_class.any_instance.stub(:disable_file_logging?).and_return(false)
      @mongodb_logger = described_class.new
    end

    [MongodbLogger::SpecHelper::LOGGER_CONFIG,
      MongodbLogger::SpecHelper::DEFAULT_CONFIG,
      MongodbLogger::SpecHelper::MONGOID_CONFIG].each do |config|
      context "during configuration when using #{config}" do
        before do
          setup_for_config(config)
        end
        after do
          cleanup_for_config(config)
        end

        should_use_database_name_in_config
      end
    end

    context "during configuration when using #{MongodbLogger::SpecHelper::DEFAULT_CONFIG_WITH_URL}" do
      before do
        setup_for_config(MongodbLogger::SpecHelper::DEFAULT_CONFIG_WITH_URL, MongodbLogger::SpecHelper::DEFAULT_CONFIG)
      end
      after do
        cleanup_for_config(MongodbLogger::SpecHelper::DEFAULT_CONFIG)
      end

      it "authenticated by url" do
        @mongodb_logger.send(:connect)
        @mongodb_logger.mongo_adapter.authenticated?.should be_true
        @mongodb_logger.db_configuration['database'].should == "system_log"
      end
    end

    context "upon connecting with authentication settings" do
      before do
        setup_for_config(MongodbLogger::SpecHelper::DEFAULT_CONFIG_WITH_AUTH, MongodbLogger::SpecHelper::DEFAULT_CONFIG)
        create_mongo_user
      end
      after do
        remove_mongo_user
        cleanup_for_config(MongodbLogger::SpecHelper::DEFAULT_CONFIG)
      end

      should_use_database_name_in_config

      it "authenticate with the credentials in the configuration" do
        @mongodb_logger.send(:connect)
        @mongodb_logger.mongo_adapter.authenticated?.should be_true
      end
    end

    context "after configuration" do
      before do
        setup_for_config(MongodbLogger::SpecHelper::DEFAULT_CONFIG)
        @mongodb_logger.send(:connect)
        @mongo_adapter = @mongodb_logger.mongo_adapter
      end

      it "set the default host, port, ssl and capsize if not configured" do
        @mongo_adapter.configuration['host'].should == 'localhost'
        @mongo_adapter.configuration['port'].should == 27017
        @mongo_adapter.configuration['capsize'].should == MongodbLogger::Logger::DEFAULT_COLLECTION_SIZE
        @mongo_adapter.configuration['ssl'].should == false
      end

      it "set the mongo collection name depending on the Rails environment" do
         @mongo_adapter.collection_name.should == "#{Rails.env}_log"
      end

      it "set the application name when specified in the config file" do
        @mongo_adapter.configuration['application_name'].should == "mongo_foo"
      end

      it "set safe insert when specified in the config file" do
        @mongo_adapter.configuration['write_options'].should be_present
      end

      it "use the database name in the config file" do
        @mongo_adapter.configuration['database'].should == "system_log"
      end

      it "not authenticate" do
        @mongo_adapter.authenticated?.should be_false
      end

      it "create a capped collection in the database with the configured size" do
        @mongodb_logger.send(:check_for_collection)
        @mongo_adapter.connection.collection_names.include?(@mongo_adapter.configuration['collection']).should be_true
        # new capped collections are X MB + 5888 bytes, but don't be too strict in case that changes
        @mongo_adapter.collection_stats[:storageSize].should < MongodbLogger::Logger::DEFAULT_COLLECTION_SIZE + 1.megabyte
      end

    end

    context "ssl" do
      before do
        setup_for_config(MongodbLogger::SpecHelper::DEFAULT_CONFIG_WITH_SSL, MongodbLogger::SpecHelper::DEFAULT_CONFIG)
      end
      after do
        cleanup_for_config(MongodbLogger::SpecHelper::DEFAULT_CONFIG)
      end

      it "be true" do
        @mongodb_logger.db_configuration['ssl'].should == true
      end
    end

  end

  context "after instantiation" do
    before do
      common_mongodb_logger_setup
    end

    context "upon insertion of a log record when active record is not used" do
      before do
        log_to_mongo("Test")
      end

      should_contain_one_log_record

      it "allow recreation of the capped collection to remove all records" do
        @mongo_adapter.reset_collection
        @mongo_adapter.collection.find.count.should == 0
      end
    end

    context "upon insertion of a colorized log record when ActiveRecord is used" do
      before do
        @log_message = "TESTING"
        log_to_mongo("\e[31m #{@log_message} \e[0m")
      end

      it "detect logging is colorized" do
        @mongodb_logger.send(:logging_colorized?).should be_true
      end

      should_contain_one_log_record

      it "strip out colorization from log messages" do
        @mongo_adapter.collection.find({"messages.debug" => @log_message}).count.should == 1
      end
    end

    it "add application metadata to the log record" do
      options = { "application" => self.class.name }
      log_metadata_to_mongo(options)
      @mongo_adapter.collection.find({"application" => self.class.name}).count.should == 1
    end

    it "not raise an exception when bson-unserializable data is logged in the :messages key" do
      log_to_mongo(Tempfile.new("foo"))
      @mongo_adapter.collection.find.count.should == 1
    end

    it "not raise an exception when bson-unserializable data is logged in the :params key" do
      log_params_to_mongo({:foo => Tempfile.new("bar")})
      @mongo_adapter.collection.find.count.should == 1
    end

    context "when an exception is raised" do
      it "log the exception" do
        expect { log_exception_to_mongo(EXCEPTION_MSG) }.to raise_error RuntimeError, EXCEPTION_MSG
        @mongo_adapter.collection.find({"messages.error" => /^#{EXCEPTION_MSG}/}).count.should == 1
        @mongo_adapter.collection.find({"is_exception" => true}).count.should == 1
      end
    end
  end

  context "after configure" do
    before do
      MongodbLogger::Base.configure do |config|
        config.on_log_exception do |mongo_record|
          # do something with error
        end
      end
      common_mongodb_logger_setup
    end

    it "not call callback function on log" do
      MongodbLogger::Base.should_receive(:on_log_exception).exactly(0)
      log_to_mongo("Test")
    end

    context "when an exception is raised" do
      it "should call callback function" do
        MongodbLogger::Base.should_receive(:on_log_exception).exactly(1)
        expect { log_exception_to_mongo(EXCEPTION_MSG) }.to raise_error RuntimeError, EXCEPTION_MSG
      end
    end
  end

  context "logging at INFO level" do
    before do
      common_mongodb_logger_setup(level: MongodbLogger::Logger::INFO)
      log_to_mongo("INFO")
    end

    should_contain_one_log_record

    it "not log DEBUG messages" do
      @mongo_adapter.collection.find({"messages.debug" => { "$exists" => true }}).count.should == 0
    end
  end

  context "without file logging" do
    before do
      setup_for_config(MongodbLogger::SpecHelper::DEFAULT_CONFIG_WITH_NO_FILE_LOGGING, MongodbLogger::SpecHelper::DEFAULT_CONFIG)
      @log_file = Pathname.new('log.out')
      FileUtils.touch(@log_file)
    end

    after do
      File.delete(@log_file)
    end

    context "in instantiation" do
      it "not call super in the initialize method" do
        described_class.should_receive(:open).exactly(0)
        MongodbLogger::Logger.new
      end

      it "set log" do
        MongodbLogger::Logger.new.instance_variable_get(:@log).should be_a_kind_of(Logger)
      end
    end

    context "after instantiation" do
      context "upon insertion of a log record" do
        before do
          @mongodb_logger = MongodbLogger::Logger.new(path: @log_file)
          log_to_mongo("Test")
        end

        it "not log the record to a file" do
          File.open(@log_file.to_s, "rb").read.should be_blank
        end
      end
    end
  end

  context "with custom collection" do
    before do
      config = MongodbLogger::SpecHelper::DEFAULT_CONFIG_WITH_COLLECTION
      common_mongodb_logger_setup({}, config)
      file_path = File.join(MongodbLogger::SpecHelper::SAMPLE_CONFIG_DIR, config)
      @file_config = YAML.load(ERB.new(File.new(file_path).read).result)[Rails.env]['mongodb_logger']
    end

    it "changed collection name" do
      @mongo_adapter.collection.name.should == @file_config['collection']
      @mongo_adapter.collection_stats[:collection].should == @file_config['collection']
    end
  end

end
