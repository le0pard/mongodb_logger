require 'rspec'

require 'mocha/api'
require 'shoulda'

require 'tempfile'
require 'pathname'
require 'fileutils'

require File.dirname(__FILE__) + "/../lib/mongodb_logger"

Dir["#{File.expand_path(File.join(File.dirname(__FILE__), "support"))}/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include MongodbLogger::SpecHelper
end
