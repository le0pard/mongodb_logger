module MongodbLogger
  module Adapers
    class Moped
      
      attr_reader :db_configuration, :mongo_connection, :mongo_collection, :insert_log_record
      
      def initialize(options = {})
        @db_configuration = options
        if @db_configuration['url']
          uri = URI.parse(@db_configuration['url'])
          @mongo_connection ||= mongo_connection_object
          @mongo_connection.use uri.path.gsub(/^\//, '')
          @authenticated = true
        else
          @mongo_connection ||= mongo_connection_object
          @mongo_connection.use @db_configuration['database']
          if @db_configuration['username'] && @db_configuration['password']
            # the driver stores credentials in case reconnection is required
            @authenticated = @mongo_connection.login(@db_configuration['username'],
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
        @mongo_collection.with(options).insert(record)
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
        {}#@mongo_collection.stats 
      end
      
      private
      
      def mongo_connection_object
        if @db_configuration['hosts']
          conn = ::Moped::Session.new(@db_configuration['hosts'], :timeout => 6)
          @db_configuration['replica_set'] = true
        elsif @db_configuration['url']
          conn = ::Moped::Session.connect(@db_configuration['url'])
        else
          conn = ::Moped::Session.new(["#{@db_configuration['host']}:#{@db_configuration['port']}"], :timeout => 6)
        end
        @mongo_connection_type = conn.class
        conn
      end
      
      def create_collection
        @mongo_connection.command(create: mongo_collection_name, capped: true, size:  @db_configuration['capsize'].to_i)
      end
      
    end
  end
end