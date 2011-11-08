require 'test/unit'
require 'shoulda'
require 'mocha'
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
  MONGOID_CONFIG = "mongoid.yml"
  REPLICA_SET_CONFIG = "database_replica_set.yml"
  LOGGER_CONFIG = "central_logger.yml"

  def log(msg)
    @central_logger.mongoize({"id" => 1}) do
      @central_logger.debug(msg)
    end
  end

  def log_params(msg)
    @central_logger.mongoize({:params => msg})
  end

  def log_exception(msg)
    @central_logger.mongoize({"id" => 1}) do
      raise msg
    end
  end

  def setup_for_config(source, dest=source)
    File.delete(File.join(CONFIG_DIR, DEFAULT_CONFIG))
    cp_config(source, dest)
    @central_logger.send(:configure)
  end

  def cp_config(source, dest=source)
    FileUtils.cp(File.join(SAMPLE_CONFIG_DIR, source),  File.join(CONFIG_DIR, dest))
  end

  def teardown_for_config(file)
    File.delete(File.join(CONFIG_DIR, file))
  end

  def log_metadata(options)
    @central_logger.mongoize({"id" => 1}) do
      @central_logger.add_metadata(options)
    end
  end

  def require_bogus_active_record
    require 'active_record'
  end

  def common_setup
    @con = @central_logger.mongo_connection
    @collection = @con[@central_logger.mongo_collection_name]
  end

  def create_user
    db_conf = @central_logger.db_configuration
    @user = db_conf['username']
    mongo_connection = Mongo::Connection.new(db_conf['host'],
                                             db_conf['port']).db(db_conf['database'])
    mongo_connection.add_user(@user, db_conf['password'])
  end

  def remove_user
    @central_logger.mongo_connection.remove_user(@user)
  end

end