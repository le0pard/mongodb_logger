require 'test_helper'
require 'mongodb_logger/logger'

# test the basic stuff
class MongodbLogger::MongodbLoggerReplicaTest < Test::Unit::TestCase
  extend LogMacros

  context "A MongodbLogger::MongoLogger" do
    setup do
      # Can use different configs, but most tests use database.yml
      cp_config(REPLICA_SET_CONFIG, DEFAULT_CONFIG)
      @mongodb_logger = MongodbLogger::Logger.new
      @mongodb_logger.reset_collection
    end

    context "upon trying to insert into a replica set voting on a new master" do
      setup do
        puts "Please disconnect the current master and hit ENTER"
        STDIN.gets
      end

      should "insert a record successfully" do
        assert_nothing_raised{ log("Test") }
        @mongodb_logger.rescue_connection_failure do
          assert_equal 1, @mongodb_logger.mongo_collection.count
        end
      end

      teardown do
        puts "Please reconnect the current master, wait for the vote to complete, then hit ENTER"
        STDIN.gets
      end
    end

    should "insert a record successfully" do
      assert_nothing_raised{ log("Test") }
      assert_equal 1, @mongodb_logger.mongo_collection.count
    end

    teardown do
      file = File.join(CONFIG_DIR, DEFAULT_CONFIG)
      File.delete(file) if File.exist?(file)
    end
  end
end