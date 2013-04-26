module MongodbLogger
  # rails 3
  class Rails3TaggedLogger < ActiveSupport::TaggedLogging
    delegate :mongoize, :add_metadata, to: :base_logger

    def base_logger
      @logger
    end
  end if ActiveSupport::TaggedLogging.instance_of?(::Class)
  # tagged logger
  module TaggedLogger
    def self.new(logger)
      defined?(Rails3TaggedLogger) ? Rails3TaggedLogger.new(logger) : ActiveSupport::TaggedLogging.new(logger)
    end
  end
end