module MongodbLogger
  module Adapers
    class Moped < Base

      def initialize(options = {})
        @configuration = options
        if @configuration[:url]
          uri = URI.parse(@configuration[:url])
          @configuration[:database] = uri.path.gsub(/^\//, '')
          @connection ||= mongo_connection_object
          @connection.use @configuration[:database]
          @authenticated = true
        else
          @connection ||= mongo_connection_object
          @connection.use @configuration[:database]
          if @configuration[:username] && @configuration[:password]
            # the driver stores credentials in case reconnection is required
            @authenticated = @connection.login(@configuration[:username],
                                                          @configuration[:password])
          end
        end
      end

      def check_for_collection
        # setup the capped collection if it doesn't already exist
        create_collection unless @connection.collection_names.include?(@configuration[:collection])
        @collection = @connection[@configuration[:collection]]
      end

      def create_collection
        @connection.command({
          create: collection_name,
          capped: @configuration[:capped],
          size: @configuration[:capsize].to_i # ignored if uncapped
        })
      end

      def insert_log_record(record, options = {})
        record[:_id] = bson_object_id.new
        @connection.with(write: options[:write_options])[collection_name].insert(record)
      end

      def collection_stats
        collection_stats_hash(@connection.command(collStats: collection_name))
      end

      def rename_collection(to, drop_target = false)
        @connection.with(database: "admin", consistency: :strong) do |session|
          rename_collection_command(session, to, drop_target)
        end
      end

      # filter
      def filter_by_conditions(filter)
        @collection.find(filter.get_mongo_conditions).limit(filter.get_mongo_limit).sort('$natural' => -1)
      end

      def find_by_id(id)
        @collection.find("_id" => bson_object_id.from_string(id)).first
      end

      def calculate_mapreduce(map, reduce, params = {})
        @connection.command(
          mapreduce: collection_name,
          map: map,
          reduce: reduce,
          query: params[:conditions],
          out: { inline: true },
          raw: true
        ).find()
      end

      private

      def mongo_connection_object
        if @configuration[:hosts]
          conn = ::Moped::Session.new(@configuration[:hosts].map{|(host,port)| "#{host}:#{port}"}, timeout: 6, ssl: @configuration[:ssl])
          @configuration['replica_set'] = true
        elsif @configuration[:url]
          conn = ::Moped::Session.connect(@configuration[:url])
        else
          conn = ::Moped::Session.new(["#{@configuration[:host]}:#{@configuration[:port]}"], timeout: 6, ssl: @configuration[:ssl])
        end
        @connection_type = conn.class
        conn
      end

      def bson_object_id
        defined?(::BSON::ObjectId) ? ::BSON::ObjectId : ::Moped::BSON::ObjectId
      end

    end
  end
end
