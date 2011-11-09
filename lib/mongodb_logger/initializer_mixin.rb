module MongodbLogger
  module InitializerMixin
    
    def create_logger(config, path)
      level = ActiveSupport::BufferedLogger.const_get(config.log_level.to_s.upcase)
      logger = MongodbLogger::Logger.new(:path => path, :level => level)
      logger.auto_flushing = false if Rails.env.production?
      logger
    rescue StandardError => e
      logger = ActiveSupport::BufferedLogger.new(STDERR)
      logger.level = ActiveSupport::BufferedLogger::WARN
      logger.warn(
        "Rails Error: Unable to access log file. Please ensure that #{path} exists and is chmod 0666. " +
        "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
      )
      logger
    end
    
  end
end