$:.unshift File.dirname(__FILE__)

require 'mongodb_logger/config'
require 'mongodb_logger/logger'
require 'mongodb_logger/railtie' if defined?(Rails::Railtie)
require 'mongodb_logger/engine' if defined?(Rails::Engine)
require 'mongodb_logger/tagged_logger' if defined?(ActiveSupport::TaggedLogging)
require 'mongodb_logger/rack_middleware'
require 'mongodb_logger/version'

module MongodbLogger
  module Base
    extend Config

    def self.included(base)
      base.class_eval do
        begin
          around_action :enable_mongodb_logger
        rescue
          around_filter :enable_mongodb_logger
        end
      end
    end

    def enable_mongodb_logger
      return yield unless Rails.logger.respond_to?(:mongoize)
      f_session = (request.respond_to?(:session) ? request.session : session)
      Rails.logger.mongoize({
        :method         => request.method,
        :action         => action_name,
        :controller     => controller_name,
        :path           => request.path,
        :url            => request.url,
        :params         => (request.respond_to?(:filtered_parameters) ? request.filtered_parameters : params),
        :session        => mongo_fix_session_keys(f_session),
        :ip             => request.remote_ip
      }) { yield }
    end
    # session keys can be with dots. It is invalid keys for BSON
    def mongo_fix_session_keys(session = {})
      new_session = {}
      session.each do |i, j|
        new_session[i.gsub(/\./i, "|")] = j.inspect
      end if session
      new_session
    end
  end
end
