#!/usr/bin/env rake
require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'rake'
require 'rake/testtask'
require 'bundler/gem_tasks'
require 'appraisal'
require 'rspec/core/rake_task'
begin
  require 'cucumber/rake/task'
rescue LoadError
  $stderr.puts "Please install cucumber: `gem install cucumber`"
  exit 1
end

#########################################
### TESTS
#########################################

desc 'Default: run tests'
task :default => [:spec, "mongodb_logger:tests"]

namespace :mongodb_logger do
  task :tests do
    exec 'rake appraisal cucumber '\
    '&& FEATURE=features/mongodb_logger_web.feature rake cucumber '\
  end
end
desc "run specs"
task :spec do
  RSpec::Core::RakeTask.new
end

desc "Clean out the tmp directory"
task :clean do
  exec "rm -rf tmp/*"
end

desc 'Test unit'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib'
  test.test_files = ['test/unit/mongodb_logger_test.rb']
  test.verbose = true
end

namespace :test do
  desc "Run replica set tests (not for CI)"
  Rake::TestTask.new(:replica_set) do |test|
    test.libs << 'lib'
    test.pattern = 'test/unit/mongodb_logger_replica_test.rb'
    test.verbose = true
  end
end

def cucumber_opts
  opts = "--tags ~@wip --format progress "

  opts << ENV["FEATURE"] and return if ENV["FEATURE"]

  case ENV["BUNDLE_GEMFILE"]
  when /rails/
    opts << "features/rails.feature"
  end
end

Cucumber::Rake::Task.new(:cucumber) do |t|
  t.fork = true
  t.cucumber_opts = cucumber_opts
end
