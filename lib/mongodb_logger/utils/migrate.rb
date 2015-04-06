require 'mongodb_logger/logger'
require 'mongodb_logger/utils/progressbar'

module MongodbLogger
  module Utils
    class Migrate

      def initialize
        raise "this task work only in Rails app" unless defined?(Rails)
      end

      def run
        Progressbar.new.show("Importing data to new capped collection") do
          @mongo_adapter, collection_name = get_mongo_adapter_and_name
          @migrate_logger = create_migration_collection(Rails.logger.db_configuration)

          iterator, all_count = 0, @mongo_adapter.collection.find.count
          @mongo_adapter.collection.find.each do |row|
            @migrate_logger.mongo_adapter.collection.insert_one(row)
            progress (((iterator += 1).to_f / all_count.to_f) * 100).round
          end if all_count > 0
          progress 100
          @migrate_logger.mongo_adapter.rename_collection(collection_name, true)
        end
      end

      def get_mongo_adapter_and_name
        mongodb_logger = Rails.logger
        collection_name = mongodb_logger.db_configuration['collection'].dup
        [mongodb_logger.mongo_adapter, collection_name]
      end

      def create_migration_collection(configuration)
        configuration.merge!({ 'collection' => "#{configuration['collection']}_copy_#{rand(100)}" })
        migrate_logger = MongoMigrateLogger.new(configuration)
        migrate_logger.mongo_adapter.reset_collection
        migrate_logger
      end

      class MongoMigrateLogger < MongodbLogger::Logger
        def initialize(config = {})
          @static_config = config
          super("/dev/null")
        end

        private
        def resolve_config
          @static_config
        end
      end


    end
  end
end