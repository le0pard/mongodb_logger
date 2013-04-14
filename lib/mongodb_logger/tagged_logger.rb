module MongodbLogger
  class TaggedLogger < ActiveSupport::TaggedLogging
    delegate :mongoize, :add_metadata, to: :base_logger

    def base_logger
      @logger
    end
  end
end