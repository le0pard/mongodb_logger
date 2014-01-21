module MongodbLogger
  module Adapers
    class Mongo < Base

      def initialize(options = {})
        @authenticated = false
        @configuration = options
        if @configuration[:url]
          uri = URI.parse(@configuration[:url])
          @configuration[:database] = uri.path.gsub(/^\//, '')
          @connection ||= mongo_connection_object.db(@configuration[:database])
          @authenticated = true
        else
          @connection ||= mongo_connection_object.db(@configuration[:database])
          if @configuration[:username] && @configuration[:password]
            # the driver stores credentials in case reconnection is required
            @authenticated = @connection.authenticate(@configuration[:username],
                                                          @configuration[:password])
          end
        end
      end

      def create_collection
        @connection.create_collection(collection_name,
          { capped: true, size: @configuration[:capsize].to_i })
      end

      def insert_log_record(record, options = {})
        record[:_id] = ::BSON::ObjectId.new
        @collection.insert(record, options[:write_options])
      end

      def collection_stats
        collection_stats_hash(@collection.stats)
      end

      def rename_collection(to, drop_target = false)
        rename_collection_command(mongo_connection_object.db("admin"), to, drop_target)
      end

      # filter
      def filter_by_conditions(filter)
        @collection.find(filter.get_mongo_conditions).limit(filter.get_mongo_limit).sort('$natural', -1)
      end

      def find_by_id(id)
        @collection.find_one(::BSON::ObjectId.from_string(id))
      end

      def calculate_mapreduce(map, reduce, params = {})
        @collection.map_reduce(map, reduce, { query: params[:conditions], sort: ['$natural', -1], out: { inline: true }, raw: true }).find()
      end

      private

      def mongo_connection_object
        if @configuration[:hosts]
          conn = ::Mongo::MongoReplicaSetClient.new(@configuration[:hosts],
            pool_timeout: 6, ssl: @configuration[:ssl])
          @configuration[:replica_set] = true
        elsif @configuration[:url]
          conn = ::Mongo::MongoClient.from_uri(@configuration[:url])
        else
          conn = ::Mongo::MongoClient.new(@configuration[:host],
                                       @configuration[:port],
                                       pool_timeout: 6,
                                       ssl: @configuration[:ssl])
        end
        @connection_type = conn.class
        conn
      end

    end
  end
end