require 'mongodb_logger/initializer_mixin'
module MongodbLogger
  class Railtie < Rails::Railtie
    include MongodbLogger::InitializerMixin

    initializer :initialize_mongodb_logger, before: :initialize_logger do
      unless MongodbLogger::Base.disabled || (mongodb_logger = create_logger(Rails.application.config)).nil?
        Rails.logger = config.logger = mongodb_logger
      end
    end

    rake_tasks do
      load File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "tasks", "mongodb_logger.rake"))
    end

  end
end
