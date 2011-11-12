#!/usr/bin/env ruby
require 'logger'

$LOAD_PATH.unshift ::File.expand_path(::File.dirname(__FILE__) + '/lib')
require 'mongodb_logger/server'

# Set the RESQUECONFIG env variable if you've a `resque.rb` or similar
# config file you want loaded on boot.
if ENV['MONGODBLOGGERCONFIG'] && ::File.exists?(::File.expand_path(ENV['MONGODBLOGGERCONFIG']))
  MongodbLogger::ServerConfig.set_config(::File.expand_path(ENV['MONGODBLOGGERCONFIG']))
else
  raise "Please provide config file"
end

use Rack::ShowExceptions
run MongodbLogger::Server.new