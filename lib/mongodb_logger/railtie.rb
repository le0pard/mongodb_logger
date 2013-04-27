require 'mongodb_logger/initializer_mixin'
module MongodbLogger
  class Railtie < Rails::Railtie
    include MongodbLogger::InitializerMixin

    initializer :initialize_mongodb_logger, before: :initialize_logger do
      Rails.logger = config.logger = create_logger(Rails.application.config)
    end

    rake_tasks do
      load File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "tasks", "mongodb_logger.rake"))
    end

  end
end
