require 'mongodb_logger/logger'
require 'mongodb_logger/utils/progressbar'

module MongodbLogger
  module Utils
    class Migrate

      def initialize(collection_name, collection_size = nil)
        raise "this task work only in Rails app" unless defined?(Rails)
        Progressbar.new.show("Importing data to #{collection_name} collection") do
          mongodb_logger = Rails.logger
          @configuration = mongodb_logger.db_configuration
          @mongo_adapter = mongodb_logger.mongo_adapter
          all_count = @mongo_adapter.collection.find.count
          raise "your collection is empty" unless all_count > 0

          if collection_size.nil? && !@mongo_adapter.connection.collection_names.include?(collection_name)
            raise "#{collection_name} not found in database"
          else
            @configuration.merge!({'collection' => collection_name, 'capsize' => collection_size})
            @migrate_logger = MongoMigrateLogger.new(@configuration)
          end

          iterator = 0
          @mongo_adapter.collection.find.each do |row|
            @migrate_logger.mongo_adapter.collection.insert(row) unless @migrate_logger.mongo_adapter.collection.find(row).first
            iterator += 1
            progress ((iterator.to_f / all_count.to_f) * 100).round
          end
        end
      end

      class MongoMigrateLogger < MongodbLogger::Logger
        def initialize(config = {})
          @static_config = config
          super(path: "/dev/null")
        end

        private
        def resolve_config
          @static_config
        end
      end


    end
  end
end