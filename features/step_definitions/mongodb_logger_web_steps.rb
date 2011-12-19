require 'active_support/core_ext/string/inflections'
require 'mongodb_logger/server'
require 'capybara/cucumber'

include Capybara::DSL

Before do
  MongodbLogger::ServerConfig.set_config_for_testing(File.join(PROJECT_ROOT, 'test/config/samples/server_config.yml'))
  Capybara.app = MongodbLogger::Server
end

After do
  MongodbLogger::ServerConfig.collection.drop
end

Given /^homepage$/ do
  visit "/"
end

Then /^I should see text that no logs in system$/ do
  page.has_content?('No logs found, try to filter out the other parameters')
  page.has_content?('Blabla')
end