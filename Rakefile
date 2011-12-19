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


#########################################
### Help tasks
#########################################

require 'coffee-script'
require 'uglifier'
namespace :js do
  desc "compile coffee-scripts from ./lib/mongodb_logger/server/coffee to ./lib/mongodb_logger/server/public/javascripts"
  task :compile do
    source = "#{File.dirname(__FILE__)}/lib/mongodb_logger/server/coffee/"
    javascripts = "#{File.dirname(__FILE__)}/lib/mongodb_logger/server/public/javascripts/"
    
    Dir.foreach(source) do |cf|
      unless cf == '.' || cf == '..' 
        js_compiled = CoffeeScript.compile File.read("#{source}#{cf}")
        js = Uglifier.compile js_compiled
        open "#{javascripts}#{cf.gsub('.coffee', '.js')}", 'w' do |f|
          f.puts js
        end 
      end 
    end
    
    puts "All done."
  end
end

#########################################
### TESTS
#########################################

desc 'Default: run unit tests.'
task :default => [:test]
#task :default => [:test, "cucumber:rails:all"]

desc "Clean out the tmp directory"
task :clean do
  exec "rm -rf tmp"
end

desc 'Test unit.'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.test_files = ['test/unit/mongodb_logger_test.rb']
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

if ENV['CI']
  # for ci testing only major rails versions
  RAILS_VERSIONS = ['3.0.11', '3.1.3'] 
else
  RAILS_VERSIONS = IO.read('SUPPORTED_RAILS_VERSIONS').strip.split("\n")
end


LOCAL_GEMS = [['sqlite3', nil], ['shoulda', nil], ["rspec", nil], ["mocha", nil], ["cucumber", nil], ["bundler", "1.0.21"]] +
  RAILS_VERSIONS.collect { |version| ['rails', version] }

desc "Vendor test gems: Run this once to prepare your test environment"
task :vendor_test_gems do
  old_gem_path = ENV['GEM_PATH']
  old_gem_home = ENV['GEM_HOME']
  ENV['GEM_PATH'] = LOCAL_GEM_ROOT
  ENV['GEM_HOME'] = LOCAL_GEM_ROOT
  LOCAL_GEMS.each do |gem_name, version|
    gem_file_pattern = [gem_name, version || '*'].compact.join('-')
    version_option = version ? "-v #{version}" : ''
    pattern = File.join(LOCAL_GEM_ROOT, 'gems', "#{gem_file_pattern}")
    existing = Dir.glob(pattern).first
    unless existing
      command = "gem install -i #{LOCAL_GEM_ROOT} --no-ri --no-rdoc --backtrace #{version_option} #{gem_name}"
      puts "Vendoring #{gem_file_pattern}..."
      unless system("#{command} 2>&1")
        puts "Command failed: #{command}"
        exit(1)
      end
    end
  end
  ENV['GEM_PATH'] = old_gem_path
  ENV['GEM_HOME'] = old_gem_home
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

def define_web_cucumber_tasks(additional_cucumber_args = '')
  namespace :web do
    desc "Test web of the gem"
    task :all do
      puts "Testing Web"
      system("cucumber --format #{ENV['CUCUMBER_FORMAT'] || 'progress'} #{additional_cucumber_args} features/mongodb_logger_web.feature")
    end
  end
end

namespace :cucumber do
  define_rails_cucumber_tasks
  define_web_cucumber_tasks
end

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue LoadError
  task :jasmine do
    abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
  end
end
