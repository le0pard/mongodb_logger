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
  page.has_selector?('div', :text => 'No logs found, try to filter out the other parameters', :visible => true)
end

Given /^I should see start tail button$/ do
  page.has_link?('tail_logs_link', :visible => true)
  page.has_link?('tail_logs_stop_link', :visible => false)
end

When /^I click on start tail button$/ do
  click_link('tail_logs_link')
end

Then /^I should see stop tails button$/ do
  page.has_link?('tail_logs_link', :visible => false)
  page.has_link?('tail_logs_stop_link', :visible => true)
end

Then /^box with time of last log tail$/ do
  page.has_selector?('span', :id => 'tail_logs_time', :visible => true)
end

When /^I click on stop tail button$/ do
  click_link('tail_logs_stop_link')
end

