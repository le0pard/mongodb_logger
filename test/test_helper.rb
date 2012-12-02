require 'test/unit'

begin
  require 'shoulda'
rescue LoadError
  require 'rubygems'
  require 'shoulda'
end

require 'mocha/setup'
# mock rails class
require 'pathname'
require 'rails'
require 'fileutils'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

Shoulda.autoload_macros("#{File.dirname(__FILE__)}/..")

class Test::Unit::TestCase
  CONFIG_DIR = Rails.root.join("config")
  SAMPLE_CONFIG_DIR = File.join(CONFIG_DIR, "samples")
  DEFAULT_CONFIG = "database.yml"
  DEFAULT_CONFIG_WITH_AUTH = "database_with_auth.yml"
  DEFAULT_CONFIG_WITH_URL = "database_with_url.yml"
  DEFAULT_CONFIG_WITH_COLLECTION = "database_with_collection.yml"
  DEFAULT_CONFIG_WITH_NO_FILE_LOGGING = "database_no_file_logging.yml"
  MONGOID_CONFIG = "mongoid.yml"
  REPLICA_SET_CONFIG = "database_replica_set.yml"
  LOGGER_CONFIG = "mongodb_logger.yml"

  def log(msg)
    @mongodb_logger.mongoize({"id" => 1}) do
      @mongodb_logger.debug(msg)
    end
  end

  def log_params(msg)
    @mongodb_logger.mongoize({:params => msg})
  end

  def log_exception(msg)
    @mongodb_logger.mongoize({"id" => 1}) do
      raise msg
    end
  end

  def setup_for_config(source, dest = source)
    File.delete(File.join(CONFIG_DIR, DEFAULT_CONFIG))
    cp_config(source, dest)
    @mongodb_logger.send(:configure)
  end

  def cp_config(source, dest = source)
    FileUtils.cp(File.join(SAMPLE_CONFIG_DIR, source),  File.join(CONFIG_DIR, dest))
  end

  def teardown_for_config(file)
    File.delete(File.join(CONFIG_DIR, file)) if File.exists?(File.join(CONFIG_DIR, file))
  end

  def log_metadata(options)
    @mongodb_logger.mongoize({"id" => 1}) do
      @mongodb_logger.add_metadata(options)
    end
  end

  def require_bogus_active_record
    require 'active_record'
  end

  def common_setup
    @mongo_adapter = @mongodb_logger.mongo_adapter
    @con = @mongo_adapter.connection
    @collection = @mongo_adapter.collection
  end
  
  def reset_collection
    if @mongo_adapter && @collection
      @collection.drop
      @mongo_adapter.create_collection
    end
  end

  def create_mongo_user
    db_conf = @mongodb_logger.db_configuration
    @user = db_conf['username']
    @mongo_connection = ::Mongo::Connection.new(db_conf['host'],
                                             db_conf['port']).db(db_conf['database'])
    @mongo_connection.add_user(@user, db_conf['password'])
  end

  def remove_mongo_user
    @mongo_connection.remove_user(@user)
  end

end
