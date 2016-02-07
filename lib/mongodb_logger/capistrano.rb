if Gem::Specification.find_by_name('capistrano').version >= Gem::Version.new('3.0.0')
  load File.expand_path('../../capistrano/tasks/capistrano3.rake', __FILE__)
else
  require File.expand_path('../../capistrano/tasks/capistrano2.rb', __FILE__)
end
