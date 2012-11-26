module MongodbLogger
  module Adapers
    class Mongo < Base
      
      def initialize(options = {})
        @authenticated = false
        @configuration = options
        if @configuration['url']
          uri = URI.parse(@configuration['url'])
          @connection ||= mongo_connection_object.db(uri.path.gsub(/^\//, ''))
          @authenticated = true
        else
          @connection ||= mongo_connection_object.db(@configuration['database'])
          if @configuration['username'] && @configuration['password']
            # the driver stores credentials in case reconnection is required
            @authenticated = @connection.authenticate(@configuration['username'],
                                                          @configuration['password'])
          end
        end
      end
      
      def create_collection
        @connection.create_collection(collection_name,
                                            {:capped => true, :size => @configuration['capsize'].to_i})
      end
      
      def insert_log_record(record, options = {})
        @collection.insert(record, options)
      end
      
      def collection_stats
        @collection.stats 
      end
      
      private
      
      def mongo_connection_object
        if @configuration['hosts']
          conn = ::Mongo::ReplSetConnection.new(*(@configuration['hosts'] <<
            {:connect => true, :pool_timeout => 6}))
          @configuration['replica_set'] = true
        elsif @configuration['url']
          conn = ::Mongo::Connection.from_uri(@configuration['url'])
        else
          conn = ::Mongo::Connection.new(@configuration['host'],
                                       @configuration['port'],
                                       :connect => true,
                                       :pool_timeout => 6)
        end
        @connection_type = conn.class
        conn
      end
      
    end
  end
end