require 'mongodb_logger/logger'

module MongodbLogger
  class ServerConfig

    class ServerLogger < MongodbLogger::Logger
      private
      def resolve_config
        config_file = ENV['MONGODBLOGGERCONFIG']
        config = YAML.load(ERB.new(File.read(config_file)).result)
        config = config['mongodb_logger'] if config && config.has_key?('mongodb_logger')
        config
      end
    end

    class << self
      def set_config(config_path)
        ENV['MONGODBLOGGERCONFIG'] = config_path
        @logger = ServerLogger.new(path: "server.log")
        @logger.mongo_adapter
      end

      def mongo_adapter
        @logger.mongo_adapter if @logger
      end
    end
  end
end