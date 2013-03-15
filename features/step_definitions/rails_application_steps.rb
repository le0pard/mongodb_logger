require 'active_support/core_ext/string/inflections'

Then /^I should (?:(not ))?see "([^\"]*)"$/ do |negator, expected_text|
  step %{the output should #{negator}contain "#{expected_text}"}
end

Then /^I should (?:(not ))?see like this \/([^\/]*)\/$/ do |negator, expected_text|
  step %{the output should #{negator}match /#{expected_text}/}
end

When /^I route "([^\"]*)" to "([^\"]*)"$/ do |path, controller_action_pair|
  route = %(get "#{path}", :to => "#{controller_action_pair}")
  routes_file = File.join(rails_root, "config", "routes.rb")
  File.open(routes_file, "r+") do |file|
    content = file.read
    content.gsub!(/^end$/, "  #{route}\nend")
    file.rewind
    file.write(content)
  end
end

When /^I route "([^\"]*)" to resources$/ do |path|
  route = %(resources :#{path})
  routes_file = File.join(rails_root, "config", "routes.rb")
  File.open(routes_file, "r+") do |file|
    content = file.read
    content.gsub!(/^end$/, "  #{route}\nend")
    file.rewind
    file.write(content)
  end
end

Then(/^I should generate in assets folder mongodb_logger files$/) do
  js_and_css = false
  Dir["#{LOCAL_RAILS_ROOT}/public/assets/*{.js,.css}"].each do |file|
    js_and_css = true unless /^mongodb_logger\-([0-9a-z]+)\.(js|css)$/.match(File.basename(file)).nil?
  end
  raise "mongodb_logger gem not installed in rails (assets not compiled)" if false == js_and_css
end

When /^I have copy tests_controller_spec$/ do
  test_file = File.join(PROJECT_ROOT, 'spec', 'factories', 'config', 'database.yml')
  target = File.join(rails_root, 'config', 'database.yml')
  FileUtils.cp(test_file, target)

  FileUtils.mkdir_p("#{rails_root}/spec")
  FileUtils.mkdir_p("#{rails_root}/spec/controllers")

  test_file = File.join(PROJECT_ROOT, 'spec', 'rails_spec', 'spec_helper_rails.rb')
  target = File.join(rails_root, 'spec', 'spec_helper.rb')
  FileUtils.cp(test_file, target)

  test_file = File.join(PROJECT_ROOT, 'spec', 'rails_spec', 'controllers', 'tests_controller_spec_rails.rb')
  target = File.join(rails_root, 'spec', 'controllers', 'tests_controller_spec.rb')
  FileUtils.cp(test_file, target)
end

When /^I have set up tests controllers$/ do
    definition = <<EOF
class ApplicationController < ActionController::Base
  protect_from_forgery
  include MongodbLogger::Base
end
EOF
  File.open(application_controller_filename, "w") {|file| file.puts definition }

  definition = <<EOF
class TestsController < ApplicationController
  LOG_MESSAGE = "FOO"
  LOG_ERROR_MESSAGE = "Error"
  LOG_USER_ID = 12345

  def index
    logger.debug LOG_MESSAGE
    logger.add_metadata(:application_name_again => Rails.root.basename.to_s, :user_id => LOG_USER_ID)
    render text: "index"
  end

  def new
    raise LOG_ERROR_MESSAGE
  end

  def create
    render text: "create"
  end

  def edit
    render text: "edit"
  end

  def update
    render text: "update"
  end

  def destroy
    render text: "destroy"
  end
end
EOF
  File.open(File.join(rails_root, 'app', 'controllers', "tests_controller.rb"), "w") {|file| file.puts definition }
end

