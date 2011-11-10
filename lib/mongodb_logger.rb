$:.unshift File.dirname(__FILE__)

require 'mongo'
require 'mongodb_logger/logger'
require 'mongodb_logger/railtie' if defined?(Rails::Railtie)
require 'mongodb_logger/version'

module MongodbLogger
  module Base
    def self.included(base)
      base.class_eval { around_filter :enable_mongodb_logger }
    end

    def enable_mongodb_logger
      return yield unless Rails.logger.respond_to?(:mongoize)
      f_params = case
                   when request.respond_to?(:filtered_parameters) then request.filtered_parameters
                   else params
                 end
      Rails.logger.mongoize({
        :method         => request.method,
        :action         => action_name,
        :controller     => controller_name,
        :path           => request.path,
        :url            => request.url,
        :params         => f_params,
        :ip             => request.remote_ip
      }) { yield }
    end
  end
end