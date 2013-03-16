require 'mongodb_logger/logger'
require 'mongodb_logger/utils/progressbar'

module MongodbLogger
  module Utils
    class Migrate

      def initialize
        raise "this task work only in Rails app" unless defined?(Rails)
        Progressbar.new.show("Importing data to new capped collection") do
          mongodb_logger = Rails.logger
          collection_name = mongodb_logger.db_configuration['collection'].dup
          @mongo_adapter = mongodb_logger.mongo_adapter
          @migrate_logger = create_migration_collection(mongodb_logger.db_configuration)

          iterator = 0
          all_count = @mongo_adapter.collection.find.count
          @mongo_adapter.collection.find.each do |row|
            @migrate_logger.mongo_adapter.collection.insert(row)
            iterator += 1
            progress ((iterator.to_f / all_count.to_f) * 100).round
          end if all_count > 0
          progress 100
          @migrate_logger.mongo_adapter.rename_collection(collection_name, true)
        end
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