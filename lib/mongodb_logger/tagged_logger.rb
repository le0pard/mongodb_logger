module MongodbLogger
  # rails 3
  if ActiveSupport::TaggedLogging.instance_of?(::Class)
    class TaggedLogger < ActiveSupport::TaggedLogging
      delegate :mongoize, :add_metadata, to: :mongo_logger

      def mongo_logger
        @logger
      end
    end
  # rails 4
  else
    # module TaggedLogger
    module TaggedLogger
      def self.new(logger)
        ActiveSupport::TaggedLogging.new(logger)
      end
    end
  end
end