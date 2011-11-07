$:.unshift File.dirname(__FILE__)

require 'mongo'
require 'mongodb_logger/logger'
require 'mongodb_logger/filter'
require 'mongodb_logger/railtie' if defined?(Rails::Railtie)
require 'mongodb_logger/version'
