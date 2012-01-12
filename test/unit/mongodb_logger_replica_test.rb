require 'test_helper'
require 'mongodb_logger/logger'

# HOWTO run this test:
# before start this test, do this in console:
# mkdir -p /tmp/data1
# mkdir -p /tmp/data2
# mkdir -p /tmp/data3
# mongod --replSet foo --port 27018 --dbpath /tmp/data1
# mongod --replSet foo --port 27019 --dbpath /tmp/data2
# mongod --replSet foo --port 27020 --dbpath /tmp/data3
# mongo localhost:27018
# In mongo console:
# config = {_id: 'foo', members: [
# {_id: 0, host: 'localhost:27018'},
# {_id: 1, host: 'localhost:27019'},
# {_id: 2, host: 'localhost:27020', arbiterOnly: true}]
# }
# 
# rs.initiate(config);
# You should see such output:
# {
#         "info" : "Config now saved locally.  Should come online in about a minute.",
#         "ok" : 1
# }


class MongodbLogger::MongodbLoggerReplicaTest < Test::Unit::TestCase
  extend LogMacros

  context "A MongodbLogger::MongoLogger connecting to a replica set" do
    setup do
      FileUtils.cp(File.join(SAMPLE_CONFIG_DIR, REPLICA_SET_CONFIG),  File.join(CONFIG_DIR, DEFAULT_CONFIG))
      MongodbLogger::Logger.any_instance.stubs(:internal_initialize).returns(nil)
      MongodbLogger::Logger.any_instance.stubs(:disable_file_logging?).returns(false)
      @mongodb_logger = MongodbLogger::Logger.new
      @mongodb_logger.send(:configure)
      @mongodb_logger.send(:connect)
      common_setup
      @collection.drop
    end

    should "derive from Mongo::ReplSetConnection" do
      assert_equal Mongo::ReplSetConnection, @mongodb_logger.mongo_connection_type
    end

    should "force replica_set parameter to be true" do
      assert @mongodb_logger.db_configuration['replica_set']
    end

    teardown do
      file = File.join(CONFIG_DIR, DEFAULT_CONFIG)
      File.delete(file) if File.exist?(file)
    end
  end
end