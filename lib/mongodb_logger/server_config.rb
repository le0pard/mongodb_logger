require 'mongo'
require 'erb'
require 'active_support'
require 'active_support/core_ext'

# TODO: Dry this class with logger class
module MongodbLogger
  class ServerConfig
    
    DEFAULT_COLLECTION_SIZE = 250.megabytes
    
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
                                    :connect => true).db(@db_configuration['database'])

        if @db_configuration['username'] && @db_configuration['password']
          @authenticated = @db.authenticate(@db_configuration['username'],
                                                          @db_configuration['password'])
        end

        set_collection
      end
      
      def set_config_for_testing(config_path)
        set_config(config_path)
        create_collection unless @db.collection_names.include?(@db_configuration["collection"])
        set_collection
      end
      
      def create_collection
        capsize = DEFAULT_COLLECTION_SIZE
        capsize = @db_configuration['capsize'].to_i if @db_configuration['capsize']
        @db.create_collection(@db_configuration["collection"],
                                            {:capped => true, :size => capsize})
      end
       
       
      def set_collection
        @collection = @db[@db_configuration["collection"]]
      end
      
      def get_config
        @db_configuration
      end
      
      def authenticated?
        @authenticated
      end
      
      def collection_name
        @db_configuration["collection"]
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