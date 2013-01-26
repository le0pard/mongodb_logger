$:.unshift File.dirname(__FILE__)

require 'mongodb_logger/config'
require 'mongodb_logger/logger'
require 'mongodb_logger/railtie' if defined?(Rails::Railtie)
require 'mongodb_logger/engine' if defined?(Rails::Engine)
require 'mongodb_logger/version'
require 'mongodb_logger/rack_middleware'

module MongodbLogger
  module Base
    extend Config
    
    def self.included(base)
      base.class_eval { around_filter :enable_mongodb_logger }
    end

    def enable_mongodb_logger
      return yield unless Rails.logger.respond_to?(:mongoize)
      f_params = case
                   when request.respond_to?(:filtered_parameters) then request.filtered_parameters
                   else params
                 end
      f_session = case
                   when request.respond_to?(:session) then request.session
                   else session
                 end
      Rails.logger.mongoize({
        :method         => request.method,
        :action         => action_name,
        :controller     => controller_name,
        :path           => request.path,
        :url            => request.url,
        :params         => f_params,
        :session        => f_session,
        :ip             => request.remote_ip
      }) { yield }
    end
  end
end
