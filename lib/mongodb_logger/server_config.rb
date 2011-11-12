require 'mongo'
require 'erb'
require 'active_support'
require 'active_support/core_ext'

module MongodbLogger
  class ServerConfig
    class << self
      def set_config(config_path)
        if File.file?(config_path)
          config_file = File.new(config_path)
          config = YAML.load(ERB.new(config_file.read).result)
        else
          raise "Config file not found"
        end
        
        @db_configuration = {
          'host' => 'localhost',
          'port' => 27017}.merge(config)
        @db_configuration["collection"] ||= "production_log"
        @db = Mongo::Connection.new(@db_configuration['host'],
                                    @db_configuration['port'],
                                    :auto_reconnect => true).db(@db_configuration['database'])

        if @db_configuration['username'] && @db_configuration['password']
          @authenticated = @db.authenticate(@db_configuration['username'],
                                                          @db_configuration['password'])
        end
        @collection = @db[@db_configuration["collection"]]
      end
       
      def get_config
        @db_configuration
      end
      
      def db
        @db
      end
      
      def collection
        @collection
      end
    end
  end
end