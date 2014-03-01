require 'rspec'

require 'tempfile'
require 'pathname'
require 'fileutils'

require File.dirname(__FILE__) + "/../lib/mongodb_logger"

ENV["RAILS_ENV"] ||= 'test'

Dir["#{File.expand_path(File.join(File.dirname(__FILE__), "support"))}/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include MongodbLogger::SpecHelper

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
