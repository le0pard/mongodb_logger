module MongodbLogger
  module Adapers
    class Mongo
      
      attr_reader :db_configuration, :mongo_connection, :mongo_collection, :insert_log_record
      
      def initialize(options = {})
        @db_configuration = options
        if @db_configuration['url']
          uri = URI.parse(@db_configuration['url'])
          @mongo_connection ||= mongo_connection_object.db(uri.path.gsub(/^\//, ''))
          @authenticated = true
        else
          @mongo_connection ||= mongo_connection_object.db(@db_configuration['database'])
          if @db_configuration['username'] && @db_configuration['password']
            # the driver stores credentials in case reconnection is required
            @authenticated = @mongo_connection.authenticate(@db_configuration['username'],
                                                          @db_configuration['password'])
          end
        end
      end
      
      def collection_name
        @db_configuration['collection']
      end
      
      def check_for_collection
        # setup the capped collection if it doesn't already exist
        create_collection unless @mongo_connection.collection_names.include?(@db_configuration['collection'])
        @mongo_collection = @mongo_connection[@db_configuration['collection']]
      end
      
      def insert_log_record(record, options = {})
        @mongo_collection.insert(record, options)
      end
      
      def reset_collection
        if @mongo_connection && @mongo_collection
          @mongo_collection.drop
          create_collection
        end 
      end
      
      def authenticated?
        @authenticated
      end
      
      def mongo_collection_stats
        @mongo_collection.stats 
      end
      
      private
      
      def mongo_connection_object
        if @db_configuration['hosts']
          conn = ::Mongo::ReplSetConnection.new(*(@db_configuration['hosts'] <<
            {:connect => true, :pool_timeout => 6}))
          @db_configuration['replica_set'] = true
        elsif @db_configuration['url']
          conn = ::Mongo::Connection.from_uri(@db_configuration['url'])
        else
          conn = ::Mongo::Connection.new(@db_configuration['host'],
                                       @db_configuration['port'],
                                       :connect => true,
                                       :pool_timeout => 6)
        end
        @mongo_connection_type = conn.class
        conn
      end
      
      def create_collection
        @mongo_connection.create_collection(@mongo_collection_name,
                                            {:capped => true, :size => @db_configuration['capsize'].to_i})
      end
      
    end
  end
end