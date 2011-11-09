#!/usr/bin/env rake
require 'rake'
require 'rake/testtask'
begin
  require 'cucumber/rake/task'
rescue LoadError
  $stderr.puts "Please install cucumber: `gem install cucumber`"
  exit 1
end

require "bundler/gem_tasks"


desc 'Default: run unit tests.'
task :default => [:test, "cucumber:rails:all"]

desc "Clean out the tmp directory"
task :clean do
  exec "rm -rf tmp"
end

desc 'Test the airbrake gem.'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/unit/mongodb_logger_test.rb'
  test.verbose = true
end

namespace :test do

  desc "Run replica set tests (not for CI)"
  Rake::TestTask.new(:replica_set) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/unit/mongodb_logger_replica_test.rb'
    test.verbose = true
  end
  
end


GEM_ROOT = File.dirname(__FILE__).freeze
LOCAL_GEM_ROOT = File.join(GEM_ROOT, 'tmp', 'local_gems').freeze
RAILS_VERSIONS = IO.read('SUPPORTED_RAILS_VERSIONS').strip.split("\n")
LOCAL_GEMS = [['sqlite3', nil]] +
  RAILS_VERSIONS.collect { |version| ['rails', version] }

desc "Install gems"
task :vendor_test_gems do
  LOCAL_GEMS.each do |gem_name, version|
    File.open(File.join(GEM_ROOT, 'Gemfile'), 'a') do |file|
      gem = "gem '#{gem_name}'"
      gem += ", '#{version}'" if version
      file.puts(gem)
    end
    @terminal.run(%{bundle install})
  end
end

Cucumber::Rake::Task.new(:cucumber) do |t|
  t.fork = true
  t.cucumber_opts = ['--format', (ENV['CUCUMBER_FORMAT'] || 'progress')]
end

task :cucumber => [:vendor_test_gems]

def run_rails_cucumbr_task(version, additional_cucumber_args)
  puts "Testing Rails #{version}"
  if version.empty?
    raise "No Rails version specified - make sure ENV['RAILS_VERSION'] is set, e.g. with `rake cucumber:rails:all`"
  end
  ENV['RAILS_VERSION'] = version
  system("cucumber --format #{ENV['CUCUMBER_FORMAT'] || 'progress'} #{additional_cucumber_args} features/rails.feature")
end

def define_rails_cucumber_tasks(additional_cucumber_args = '')
  namespace :rails do
    RAILS_VERSIONS.each do |version|
      desc "Test integration of the gem with Rails #{version}"
      task version => [:vendor_test_gems] do
        exit 1 unless run_rails_cucumbr_task(version, additional_cucumber_args)
      end
    end

    desc "Test integration of the gem with all Rails versions"
    task :all do
      results = RAILS_VERSIONS.map do |version|
        run_rails_cucumbr_task(version, additional_cucumber_args)
      end

      exit 1 unless results.all?
    end
  end
end

namespace :cucumber do
  define_rails_cucumber_tasks
end
