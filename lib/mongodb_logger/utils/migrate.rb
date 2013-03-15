require 'mongodb_logger/logger'
require 'mongodb_logger/utils/progressbar'

module MongodbLogger
  module Utils
    class Migrate

      def initialize
        raise "this task work only in Rails app" unless defined?(Rails)
        Progressbar.new.show("Importing data to new capped collection") do
          mongodb_logger = Rails.logger
          @configuration = mongodb_logger.db_configuration
          @mongo_adapter = mongodb_logger.mongo_adapter
          all_count = @mongo_adapter.collection.find.count

          collection_name = @configuration['collection'].dup
          tmp_collection_name = "#{@configuration['collection']}_copy_#{rand(100)}"
          @configuration.merge!({ 'collection' => tmp_collection_name })
          @migrate_logger = MongoMigrateLogger.new(@configuration)
          @migrate_logger.mongo_adapter.reset_collection

          iterator = 0
          @mongo_adapter.collection.find.each do |row|
            @migrate_logger.mongo_adapter.collection.insert(row)
            iterator += 1
            progress ((iterator.to_f / all_count.to_f) * 100).round
          end
          @migrate_logger.mongo_adapter.rename_collection(collection_name, true)
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