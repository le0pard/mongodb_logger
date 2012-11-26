module MongodbLogger
  module Adapers
    class Moped < Base
      
      attr_reader :configuration, :connection, :connection_type, :collection
      
      def initialize(options = {})
        @configuration = options
        if @configuration['url']
          uri = URI.parse(@configuration['url'])
          @connection ||= mongo_connection_object
          @connection.use uri.path.gsub(/^\//, '')
          @authenticated = true
        else
          @connection ||= mongo_connection_object
          @connection.use @configuration['database']
          if @configuration['username'] && @configuration['password']
            # the driver stores credentials in case reconnection is required
            @authenticated = @connection.login(@configuration['username'],
                                                          @configuration['password'])
          end
        end
      end
      
      def collection_name
        @configuration['collection']
      end
      
      def check_for_collection
        # setup the capped collection if it doesn't already exist
        create_collection unless @connection.collection_names.include?(@configuration['collection'])
        @collection = @connection[@configuration['collection']]
      end
      
      def insert_log_record(record, options = {})
        @collection.with(options).insert(record)
      end
      
      def reset_collection
        if @connection && @collection
          @collection.drop
          create_collection
        end 
      end
      
      def authenticated?
        @authenticated
      end
      
      def collection_stats
        {}#@collection.stats 
      end
      
      private
      
      def mongo_connection_object
        if @configuration['hosts']
          conn = ::Moped::Session.new(@configuration['hosts'], :timeout => 6)
          @configuration['replica_set'] = true
        elsif @configuration['url']
          conn = ::Moped::Session.connect(@configuration['url'])
        else
          conn = ::Moped::Session.new(["#{@configuration['host']}:#{@configuration['port']}"], :timeout => 6)
        end
        @mongo_connection_type = conn.class
        conn
      end
      
      def create_collection
        @connection.command(create: collection_name, capped: true, size:  @configuration['capsize'].to_i)
      end
      
    end
  end
end