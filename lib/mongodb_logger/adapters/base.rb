module MongodbLogger
  module Adapers
    class Base

      attr_reader :configuration, :connection, :connection_type, :collection, :authenticated

      def collection_name
        @configuration[:collection]
      end

      def authenticated?
        @authenticated
      end

      def check_for_collection
        raise "Not implemented"
      end

      def rename_collection_command(admin_session, to, drop_target = false)
        admin_session.command(renameCollection: "#{@configuration[:database]}.#{collection_name}", to: "#{@configuration[:database]}.#{to}", dropTarget: drop_target)
      end

      def reset_collection
        if @connection && @collection
          @collection.drop
          create_collection
        end
      end

      def collection_stats_hash(stats)
        {
          is_capped: [1, true].include?(stats["capped"]),
          count: stats["count"].to_i,
          size: stats["size"].to_f,
          maxSize: stats["maxSize"].to_f,
          db_name: @configuration["database"],
          collection: collection_name
        }
      end

      def create_collection
        raise "Not implemented"
      end

    end
  end
end
