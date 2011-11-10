require 'mongodb_logger/initializer_mixin'
module MongodbLogger
  class Railtie < Rails::Railtie
    include MongodbLogger::InitializerMixin
    
    initializer :initialize_mongodb_logger, :before => :initialize_logger do
      app_config = Rails.application.config
      Rails.logger = config.logger = create_logger(app_config,
            ((app_config.paths['log'] rescue nil) || app_config.paths.log.to_a).first)
    end
    
  end
end
