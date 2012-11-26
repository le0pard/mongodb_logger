module MongodbLogger
  module Adapers
    class Base

      attr_reader :configuration, :connection, :connection_type, :collection, :authenticated

      def collection_name
        @configuration['collection']
      end

      def authenticated?
        @authenticated
      end

      def check_for_collection
        # setup the capped collection if it doesn't already exist
        create_collection unless @connection.collection_names.include?(@configuration['collection'])
        @collection = @connection[@configuration['collection']]
      end

      def reset_collection
        if @connection && @collection
          @collection.drop
          create_collection
        end
      end

      def create_collection
        raise "Not implemented"
      end

    end
  end
end