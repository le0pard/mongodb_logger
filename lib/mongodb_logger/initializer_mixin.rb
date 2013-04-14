module MongodbLogger
  module InitializerMixin

    def rails3(minor = 0)
      3 == Rails::VERSION::MAJOR && minor == Rails::VERSION::MINOR
    end

    def create_logger(config)
      path = config.paths['log'].first
      level = ActiveSupport::BufferedLogger.const_get(config.log_level.to_s.upcase)
      logger = MongodbLogger::Logger.new(:path => path, :level => level)
      # decorating with TaggedLogging
      logger = MongodbLogger::TaggedLogger.new(logger) if defined?(ActiveSupport::TaggedLogging)
      logger.level = level
      logger.auto_flushing = false if Rails.env.production? && rails3(1)
      logger
    rescue StandardError => e
      logger = ActiveSupport::BufferedLogger.new(STDERR)
      logger.level = ActiveSupport::BufferedLogger::WARN
      logger.warn(
        "MongodbLogger Initializer Error: Unable to access log file. Please ensure that #{path} exists and is chmod 0666. " +
        "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed." + "\n" +
        e.message + "\n" + e.backtrace.join("\n")
      )
      logger
    end

  end
end
