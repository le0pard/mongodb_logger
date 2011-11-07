# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mongodb_logger/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Alexey Vasiliev"]
  gem.email         = ["leopard.not.a@gmail.com"]
  gem.description   = %q{MongoDB logger for Rails 3}
  gem.summary       = %q{}
  gem.homepage      = ""

  gem.add_development_dependency "mongo"
  gem.add_development_dependency "bson_ext"

  gem.rubyforge_project = "mongodb_logger"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "mongodb_logger"
  gem.require_paths = ["lib"]
  gem.version       = MongodbLogger::VERSION
end
