module MongodbLogger
  module Adapers
    class Mongo < Base

      def initialize(options = {})
        @authenticated = false
        @configuration = options
        if @configuration['url']
          uri = URI.parse(@configuration['url'])
          @configuration['database'] = uri.path.gsub(/^\//, '')
          @connection ||= mongo_connection_object.db(@configuration['database'])
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
        @collection.find(filter.get_mongo_conditions).sort('$natural', -1).limit(filter.get_mongo_limit)
      end

      def find_by_id(id)
        @collection.find_one(::BSON::ObjectId(id))
      end

      def tail_log_from_params(params = {})
        logs = []
        last_id = nil
        if params[:log_last_id] && !params[:log_last_id].blank?
          log_last_id = params[:log_last_id]
          @collection.find({'_id' => { '$gt' => ::BSON::ObjectId(log_last_id) }}).sort('$natural', -1).each do |log|
            logs << log
            log_last_id = log["_id"].to_s
          end
          logs.reverse!
        else
          log = @collection.find_one({}, {:sort => ['$natural', -1]})
          log_last_id = log["_id"].to_s unless log.blank?
        end
        {
          :log_last_id => log_last_id,
          :time => Time.now.strftime("%F %T"),
          :logs => logs
        }
      end

      def calculate_mapreduce(map, reduce, params = {})
        @collection.map_reduce(map, reduce, {:query => params[:conditions], :sort => ['$natural', -1], :out => {:inline => true}, :raw => true}).find()
      end

      private

      def mongo_connection_object
        if @configuration['hosts']
          conn = ::Mongo::MongoReplicaSetClient.new(@configuration['hosts'],
            :pool_timeout => 6, :ssl => @configuration['ssl'])
          @configuration['replica_set'] = true
        elsif @configuration['url']
          conn = ::Mongo::MongoClient.from_uri(@configuration['url'])
        else
          conn = ::Mongo::MongoClient.new(@configuration['host'],
                                       @configuration['port'],
                                       :pool_timeout => 6,
                                       :ssl => @configuration['ssl'])
        end
        @connection_type = conn.class
        conn
      end

    end
  end
end