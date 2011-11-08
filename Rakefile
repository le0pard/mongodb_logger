#!/usr/bin/env rake
require 'rake'
require 'rake/testtask'
require "bundler/gem_tasks"

desc 'Default: run unit tests.'
task :default => "test:units"
task :test => "test:functionals"


namespace :test do
  desc "Run all tests against all permutations of ruby and rails"
  task :functionals do
    #rake_functionals
  end

  namespace :functionals do
    desc "Clean out gemsets before running functional tests."
    task :clean do
      rake_functionals('--clean')
    end
  end

  desc "Run unit tests"
  Rake::TestTask.new(:units) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/unit/mongodb_logger_test.rb'
    test.verbose = true
  end

  desc "Run replica set tests"
  Rake::TestTask.new(:replica_set) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/unit/mongodb_logger_replica_test.rb'
    test.verbose = true
  end
end
