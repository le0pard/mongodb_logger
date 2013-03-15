require 'spec_helper'
require File.dirname(__FILE__) + "/../../lib/mongodb_logger/utils/migrate"

describe MongodbLogger::Utils::Migrate do
  extend MongodbLogger::SpecMacros

  context "migrate" do
    before do
      common_mongodb_logger_setup
    end

    it "cap collection the same size as in config" do
      @mongo_adapter.collection_stats[:storageSize].should >= MongodbLogger::Logger::DEFAULT_COLLECTION_SIZE
      @mongo_adapter.collection_stats[:storageSize].should < MongodbLogger::Logger::DEFAULT_COLLECTION_SIZE + 1.megabyte
    end

    context 'after change config' do
      before do
        setup_for_config(MongodbLogger::SpecHelper::DEFAULT_CONFIG_CAPSIZE, MongodbLogger::SpecHelper::DEFAULT_CONFIG)
      end

      it "nothing changed" do
        @mongo_adapter.collection_stats[:storageSize].should >= MongodbLogger::Logger::DEFAULT_COLLECTION_SIZE
        @mongo_adapter.collection_stats[:storageSize].should < MongodbLogger::Logger::DEFAULT_COLLECTION_SIZE + 1.megabyte
      end

      it 'changed after migration' do
        MongodbLogger::Utils::Migrate.new
        @mongodb_logger = MongodbLogger::Logger.new
        @mongo_adapter = @mongodb_logger.mongo_adapter
        @mongo_adapter.collection_stats[:storageSize].should >= 50.megabyte
        @mongo_adapter.collection_stats[:storageSize].should < 51.megabyte
      end
    end

  end

end
