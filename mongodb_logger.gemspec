# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mongodb_logger/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Alexey Vasiliev"]
  gem.email         = ["leopard.not.a@gmail.com"]
  gem.description   = %q{MongoDB logger for Rails 3}
  gem.summary       = %q{MongoDB logger for Rails 3}
  gem.homepage      = ""

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "mocha"
  
  gem.add_runtime_dependency "bundler", ">= 1.0.0"
  gem.add_runtime_dependency "mongo", "~> 1.4.0"
  gem.add_runtime_dependency "bson_ext", "~> 1.4.0"
  gem.add_runtime_dependency "activesupport", ">= 3.0.0"
  gem.add_runtime_dependency "sinatra", "~> 1.3.0"
  gem.add_runtime_dependency "haml", "~> 3.1.3"
  gem.add_runtime_dependency "coffee-script", "~> 2.2.0"
  gem.add_runtime_dependency "vegas", "~> 0.1.2"

  gem.rubyforge_project = "mongodb_logger"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "mongodb_logger"
  gem.require_paths = ["lib"]
  gem.version       = MongodbLogger::VERSION
end
