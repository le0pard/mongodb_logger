#!/usr/bin/env ruby
require 'logger'

$LOAD_PATH.unshift ::File.expand_path(::File.dirname(__FILE__) + '/lib')
require 'mongodb_logger/server'

# Set the MONGODBLOGGERCONFIG env variable
# config file you want loaded on boot.
if ENV['MONGODBLOGGERCONFIG'] && ::File.file?(::File.expand_path(ENV['MONGODBLOGGERCONFIG']))
  MongodbLogger::ServerConfig.set_config(::File.expand_path(ENV['MONGODBLOGGERCONFIG']))
  use Rack::ShowExceptions

  map '/assets' do
    run MongodbLogger::Assets.instance
  end

  map '/' do
    run MongodbLogger::Server.new
  end
else
  raise "Please provide config file"
  exit 1
end

