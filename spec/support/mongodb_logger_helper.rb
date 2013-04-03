require 'mongo'
require File.expand_path(File.join(File.dirname(__FILE__), "rails.rb"))

module MongodbLogger::SpecHelper
  CONFIG_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "tmp", "config"))
  SAMPLE_CONFIG_DIR = File.expand_path(File.join(File.dirname(__FILE__), "..", "factories", "config"))
  DEFAULT_CONFIG = "database.yml"
  DEFAULT_CONFIG_WITH_AUTH = "database_with_auth.yml"
  DEFAULT_CONFIG_CAPSIZE = "database_with_capsize.yml"
  DEFAULT_CONFIG_WITH_URL = "database_with_url.yml"
  DEFAULT_CONFIG_WITH_SSL = "database_with_ssl.yml"
  DEFAULT_CONFIG_WITH_COLLECTION = "database_with_collection.yml"
  DEFAULT_CONFIG_WITH_NO_FILE_LOGGING = "database_no_file_logging.yml"
  REPLICA_SET_CONFIG = "database_replica_set.yml"
  MONGOID_CONFIG = "mongoid.yml"
  LOGGER_CONFIG = "mongodb_logger.yml"

  def create_logs_dir
    FileUtils.mkdir_p(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "tmp", "log")))
    FileUtils.mkdir_p(CONFIG_DIR)
    FileUtils.mkdir_p(File.join(CONFIG_DIR, "log"))
  end

  def setup_for_config(source, dest = source)
    File.delete(File.join(CONFIG_DIR, DEFAULT_CONFIG)) if File.exists?(File.join(CONFIG_DIR, DEFAULT_CONFIG))
    cp_config(source, dest)
    @mongodb_logger.send(:configure) if @mongodb_logger
  end

  def cp_config(source, dest = source)
    FileUtils.cp(File.join(SAMPLE_CONFIG_DIR, source),  File.join(CONFIG_DIR, dest))
  end

  def cleanup_for_config(file)
    File.delete(File.join(CONFIG_DIR, file)) if File.exists?(File.join(CONFIG_DIR, file))
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

  def common_mongodb_logger_setup(options = {}, config = DEFAULT_CONFIG)
    cp_config(config, DEFAULT_CONFIG)
    @mongodb_logger = MongodbLogger::Logger.new(options)
    @mongo_adapter = @mongodb_logger.mongo_adapter
    @mongo_adapter.reset_collection
  end

  # logs
  def log_to_mongo(msg)
    @mongodb_logger.mongoize({"id" => 1}) do
      @mongodb_logger.debug(msg)
    end
  end

  def log_metadata_to_mongo(options)
    @mongodb_logger.mongoize({"id" => 1}) do
      @mongodb_logger.add_metadata(options)
    end
  end

  def log_params_to_mongo(msg)
    @mongodb_logger.mongoize({:params => msg})
  end

  def log_exception_to_mongo(msg)
    @mongodb_logger.mongoize({"id" => 1}) do
      raise msg
    end
  end

end