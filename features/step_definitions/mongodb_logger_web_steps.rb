require 'active_support/core_ext/string/inflections'
require 'mongodb_logger/server'
require 'capybara'
require 'capybara/cucumber'
require 'capybara/dsl'

Before do
  # silent logs
  if defined?(Mongo) && defined?(Mongo::Logger)
    Mongo::Logger.logger = Logger.new($stdout)
    Mongo::Logger.logger.level = Logger::INFO
  end
  # setup
  @mongo_adapter = MongodbLogger::ServerConfig.set_config(File.join(PROJECT_ROOT, 'spec/factories/config/server_config.yml'))
  @mongo_adapter.reset_collection
  Capybara.default_wait_time = 5
  Capybara.default_selector = :css
  Capybara.app = Rack::Builder.new do
    map('/assets')  { run MongodbLogger::Assets.instance }
    map('/')        { run MongodbLogger::Server.new }
  end
  # Override default rack_test driver to respect data-method attributes.
  Capybara.register_driver :rack_test do |app|
    Capybara::RackTest::Driver.new(app, respect_data_method: true)
  end
end

After do
  @mongo_adapter.collection.drop
end

Given /^homepage$/ do
  visit "/"
end

Then /^I should see text that no logs in system$/ do
  page.has_selector?('div', text: 'No logs found, try to filter out the other parameters', visible: true)
end

Given /^I should see show filter button$/ do
  page.has_link?('filterLogsLink', visible: true)
  page.has_link?('filterLogsStopLink', visible: false)
end

When /^I click on show filter button$/ do
  click_link('filterLogsLink')
end

Then /^I should see hide filter button$/ do
  page.has_link?('filterLogsLink', visible: false)
  page.has_link?('filterLogsStopLink', visible: true)
end

When /^I click on hide filter button$/ do
  click_link('filterLogsStopLink')
end

