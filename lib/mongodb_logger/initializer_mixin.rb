require 'mongodb_logger/rails_logger'

module MongodbLogger
  module InitializerMixin

    def create_logger(config)
      path = config.paths['log'].first
      level = RailsLogger.const_get(config.log_level.to_s.upcase)
      logger = MongodbLogger::Logger.new(path, level)
      # decorating with TaggedLogging
      logger = MongodbLogger::TaggedLogger.new(logger) if defined?(ActiveSupport::TaggedLogging)
      logger.level = level
      logger
    rescue StandardError => e
      logger = RailsLogger.new(STDERR)
      logger.level = RailsLogger::WARN
      logger.warn(
        "MongodbLogger Initializer Error: Rails will switched to standard logger." + "\n" +
        e.message + "\n" + e.backtrace.join("\n")
      )
      (ENV['HEROKU_RACK'] ? logger : nil) # use standard rails logger, except heroku
    end

  end
end
