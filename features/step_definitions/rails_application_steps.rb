require 'active_support/core_ext/string/inflections'

Given /^I have built and installed the "([^\"]*)" gem$/ do |gem_name|
  @terminal.build_and_install_gem(File.join(PROJECT_ROOT, "#{gem_name}.gemspec"))
end

When /^I generate a new Rails application$/ do
  @terminal.cd(TEMP_DIR)
  version_string = ENV['RAILS_VERSION']
  rails_create_command = 'new'

  load_rails = <<-RUBY
    gem 'rails', '#{version_string}'; \
    load Gem.bin_path('rails', 'rails', '#{version_string}')
  RUBY

  @terminal.run(%{ruby -rrubygems -rthread -e "#{load_rails.strip!}" #{rails_create_command} rails_root})
  if rails_root_exists?
    @terminal.echo("Generated a Rails #{version_string} application")
  else
    raise "Unable to generate a Rails application:\n#{@terminal.output}"
  end
  require_thread if rails30?
end

When /^I configure my application to require the "([^\"]*)" gem(?: with version "(.+)")?$/ do |gem_name, version|
  bundle_gem(gem_name, version)
end

When /^I setup mongodb_logger tests$/ do
  copy_tests
  add_routes
end

Then /^the tests should have run successfully$/ do
  bundle_gem("therubyracer", nil) if rails31?
  step %{I run "#{File.join(LOCAL_GEM_ROOT, 'bin', 'bundle')} install"}
  @terminal.status.exitstatus.should == 0
  step %{I run "#{File.join(LOCAL_GEM_ROOT, 'bin', 'bundle')} exec rake db:create db:migrate RAILS_ENV=test --trace"}
  @terminal.status.exitstatus.should == 0
  step %{I run "#{File.join(LOCAL_GEM_ROOT, 'bin', 'bundle')} exec rake test RAILS_ENV=test --trace"}
  @terminal.status.exitstatus.should == 0
end

When /^I run "([^\"]*)"$/ do |command|
  @terminal.cd(rails_root)
  @terminal.run(command)
end