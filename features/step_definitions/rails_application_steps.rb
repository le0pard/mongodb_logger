require 'active_support/core_ext/string/inflections'

Given /^I have built and installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.build_and_install_gem(File.join(PROJECT_ROOT, "#{gem_name}.gemspec"))
end

When /^I generate a new Rails application$/ do
  @terminal.cd(TEMP_DIR)
  version_string = ENV['RAILS_VERSION']
  rails_create_command = 'new'

  load_rails = <<-RUBY
    gem "rails", "#{version_string}"; \
    load Gem.bin_path("rails", "rails", "#{version_string}")
  RUBY

  @terminal.run(%{ruby -rrubygems -rthread -e "#{load_rails.gsub("\"", "\\\"").strip!}" #{rails_create_command} rails_root})
  if rails_root_exists?
    @terminal.echo("Generated a Rails #{version_string} application")
  else
    raise "Unable to generate a Rails application:\n#{@terminal.output}"
  end
  #require_thread if rails30?
end

When /^I configure my application to require the "([^\"]*)" gem(?: with version "(.+)")?$/ do |gem_name, version|
  bundle_gem(gem_name, version)
end

When /^I setup mongodb_logger tests$/ do
  copy_tests
  add_routes
end

When /^I setup all gems for rails$/ do
  bundle_gem("therubyracer", nil) if rails31?
  step %{I run "bundle install"}
  @terminal.status.exitstatus.should == 0
end

When /^I prepare rails environment for testing$/ do
  step %{I run "rake db:create db:migrate RAILS_ENV=test"}
  @terminal.status.exitstatus.should == 0
end


Then /^the tests should have run successfully$/ do
  step %{I run "rake test RAILS_ENV=test"}
  @terminal.status.exitstatus.should == 0
  # show errors
  puts @terminal.output if 1 != @terminal.output.scan(/fail: 0,  error: 0/).size
  # check if have errors
  @terminal.output.scan(/fail: 0,  error: 0/).size.should == 1
end

When /^I run "([^\"]*)"$/ do |command|
  @terminal.cd(rails_root)
  @terminal.run(command)
end
