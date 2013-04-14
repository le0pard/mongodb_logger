# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongodb_logger/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Alexey Vasiliev"]
  gem.email         = ["leopard.not.a@gmail.com"]
  gem.description   = %q{MongoDB logger for Rails}
  gem.summary       = %q{MongoDB logger for Rails}
  gem.homepage      = "http://mongodb-logger.catware.org"

  gem.extra_rdoc_files  = [ "LICENSE", "README.md" ]
  gem.rdoc_options      = ["--charset=UTF-8"]

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rspec-rails"
  gem.add_development_dependency "shoulda"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "cucumber"
  gem.add_development_dependency "cucumber-rails"
  gem.add_development_dependency "capybara", '2.0.3'
  gem.add_development_dependency "coffee-script"
  gem.add_development_dependency "uglifier"
  gem.add_development_dependency "jasmine"
  gem.add_development_dependency "appraisal"
  gem.add_development_dependency "aruba"
  # adapters
  gem.add_development_dependency "mongo"
  gem.add_development_dependency "moped"

  gem.add_dependency "rake",            ">= 0.9.0"
  gem.add_dependency "multi_json",      ">= 1.6.0"
  gem.add_dependency "activesupport",   ">= 3.1.0"
  gem.add_dependency "actionpack",      ">= 3.1.0"
  gem.add_dependency "sprockets",       ">= 2.0.0"
  gem.add_dependency "sinatra",         ">= 1.3.0"
  gem.add_dependency "erubis",          ">= 2.7.0"
  gem.add_dependency "mustache",        ">= 0.99.0"
  gem.add_dependency "vegas",           "~> 0.1.0"

  gem.rubyforge_project = "mongodb_logger"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "mongodb_logger"
  gem.require_paths = ["lib"]
  gem.version       = MongodbLogger::VERSION
end
