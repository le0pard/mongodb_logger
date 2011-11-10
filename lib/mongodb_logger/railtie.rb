require 'mongodb_logger/initializer_mixin'
module MongodbLogger
  class Railtie < Rails::Railtie
    include MongodbLogger::InitializerMixin
    
    initializer :initialize_mongodb_logger, :before => :initialize_logger do
      app_config = Rails.application.config
      Rails.logger = config.logger = create_logger(app_config)
    end
    
  end
end
