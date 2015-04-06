require 'rubygems'
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

if defined?(Mongo) && defined?(Mongo::Logger)
  Mongo::Logger.logger = Logger.new($stdout)
  Mongo::Logger.logger.level = Logger::INFO
end

RSpec.configure do |config|

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

end
