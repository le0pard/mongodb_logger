module MongodbLogger
  # Change config options in an initializer:
  #
  # MongodbLogger::Base.on_log_exception do |mongo_record|
  #   ... call some code ...
  # end
  #
  # Or in a block:
  #
  # MongodbLogger::Base.configure do |config|
  #   config.on_log_exception do |mongo_record|
  #     ... call some code ...
  #   end
  # end

  module Config
    extend self
    attr_writer :on_log_exception, :disabled

    def configure
      yield self
    end

    def on_log_exception(*args, &block)
      if block
        @on_log_exception = block
      elsif @on_log_exception
        @on_log_exception.call(*args)
      end
    end

    def disabled
      @disabled ||= false
    end

  end
end