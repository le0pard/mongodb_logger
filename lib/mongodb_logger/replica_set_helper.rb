module MongodbLogger
  module ReplicaSetHelper
    # Use retry alg from mongodb to gobble up connection failures during replica set master vote
    # Defaults to a 10 second wait
    def rescue_connection_failure(max_retries = 40)
      success = false
      retries = 0
      while !success
        begin
          yield
          success = true
        rescue mongo_error_type => e
          raise e if (retries += 1) >= max_retries
          sleep 0.25
        end
      end
    end
    
    private
    
    def mongo_error_type
      return @mongo_error if @mongo_error
      @mongo_error = Mongo::ConnectionFailure if defined?(Mongo) && defined?(Mongo::ConnectionFailure)
      @mongo_error = Moped::SocketError  if defined?(Moped) && defined?(Moped::SocketError)
      @mongo_error
    end
  end
end