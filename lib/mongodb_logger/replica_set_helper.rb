module MongodbLogger
  module ReplicaSetHelper
    # Use retry alg from mongodb to gobble up connection failures during replica set master vote
    # Defaults to a 10 second wait
    def rescue_connection_failure(max_retries=40)
      success = false
      retries = 0
      while !success
        begin
          yield
          success = true
        rescue Mongo::ConnectionFailure => e
          raise e if (retries += 1) >= max_retries
          sleep 0.25
        end
      end
    end
  end
end