module MongodbLogger
  module Adapers
    class Moped < Base

      def initialize(options = {})
        @configuration = options
        if @configuration['url']
          uri = URI.parse(@configuration['url'])
          @configuration['database'] = uri.path.gsub(/^\//, '')
          @connection ||= mongo_connection_object
          @connection.use @configuration['database']
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

      def create_collection
        @connection.command(create: collection_name, capped: true, size:  @configuration['capsize'].to_i)
      end

      def insert_log_record(record, options = {})
        record[:_id] = ::Moped::BSON::ObjectId.new
        @connection.with(safe: options[:write_options])[collection_name].insert(record)
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
        @collection.find(filter.get_mongo_conditions).sort('$natural' => -1).limit(filter.get_mongo_limit)
      end

      def find_by_id(id)
        @collection.find("_id" => ::Moped::BSON::ObjectId.from_string(id)).first
      end

      def tail_log_from_params(params = {})
        logs = []
        last_id = nil
        if params[:log_last_id] && !params[:log_last_id].blank?
          log_last_id = params[:log_last_id]
          @collection.find({'_id' => { '$gt' => ::Moped::BSON::ObjectId.from_string(log_last_id) }}).sort('$natural' => -1).each do |log|
            logs << log
            log_last_id = log["_id"].to_s
          end
          logs.reverse!
        else
          log = @collection.find.sort('$natural' => -1).first
          log_last_id = log["_id"].to_s unless log.blank?
        end
        {
          :log_last_id => log_last_id,
          :time => Time.now.strftime("%F %T"),
          :logs => logs
        }
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
        if @configuration['hosts']
          conn = ::Moped::Session.new(@configuration['hosts'].map{|(host,port)| "#{host}:#{port}"}, :timeout => 6, :ssl => @configuration['ssl'])
          @configuration['replica_set'] = true
        elsif @configuration['url']
          conn = ::Moped::Session.connect(@configuration['url'])
        else
          conn = ::Moped::Session.new(["#{@configuration['host']}:#{@configuration['port']}"], :timeout => 6, :ssl => @configuration['ssl'])
        end
        @connection_type = conn.class
        conn
      end

    end
  end
end