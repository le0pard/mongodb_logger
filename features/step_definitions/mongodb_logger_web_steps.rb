require 'active_support/core_ext/string/inflections'
require 'mongodb_logger/server'
require 'capybara'
require 'capybara/cucumber'
require 'capybara/dsl'

Before do
  @mongo_adapter = MongodbLogger::ServerConfig.set_config(File.join(PROJECT_ROOT, 'spec/factories/config/server_config.yml'))
  @mongo_adapter.reset_collection
  Capybara.default_selector = :css
  Capybara.app = Rack::Builder.new do
    map('/assets')  { run MongodbLogger::Assets.instance }
    map('/')        { run MongodbLogger::Server.new }
  end
end

After do
  @mongo_adapter.collection.drop
end

Given /^homepage$/ do
  visit "/"
end

Then /^I should see text that no logs in system$/ do
  page.has_selector?('div', :text => 'No logs found, try to filter out the other parameters', :visible => true)
end

Given /^I should see start tail button$/ do
  page.has_link?('tailLogsLink', :visible => true)
  page.has_link?('tailLogsStopLink', :visible => false)
end

When /^I click on start tail button$/ do
  click_link('tailLogsLink')
end

Then /^I should see stop tails button$/ do
  page.has_link?('tailLogsLink', :visible => false)
  page.has_link?('tailLogsStopLink', :visible => true)
end

Then /^box with time of last log tail$/ do
  page.has_selector?('span#tailLogsTime', :visible => true)
end

When /^I click on stop tail button$/ do
  click_link('tailLogsStopLink')
end

