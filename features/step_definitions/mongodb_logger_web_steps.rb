require 'active_support/core_ext/string/inflections'
require 'mongodb_logger/server'
require 'capybara/cucumber'

include Capybara::DSL

Before do
  Capybara.app = MongodbLogger::Server
end

Given /^homepage$/ do
  visit "/"
end

Then /^I should see list of logs$/ do
  page.should have_selector('table', :id => 'logs_list')
end